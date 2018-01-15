# ConnectionManager 3.0.0

The ConnectionManager class is an Electric Imp device-side library aimed at simplifying connect and disconnect flows.

**Note** If you are using the ConnectionManager class in your model, you should ensure that you *never* call  [**server.connect()**](https://electricimp.com/docs/api/server/connect/) or [**server.disconnect()**](https://electricimp.com/docs/api/server/disconnect/) in your application code. Instead you should use the ConnectionManager’s *connect()* and *disconnect()* methods.

**To add this library to your project, add** `#require "ConnectionManager.lib.nut:2.0.0"` **to the top of your device code.**

## Class Usage

### Constructor: ConnectionManager(*[settings]*)

The ConnectionManager class can be instantiated with an optional table of settings that modify its behavior. The following settings are available:

| key                 | default             | notes |
| ------------------- | ------------------- | ----- |
| *startBehavior*     | START_NO_ACTION     | See below |
| *stayConnected*     | `false`             | When set to `true` the device will aggressively attempt to reconnect when disconnected |
| *retryOnTimeout*    | `true`              | When set to `true` the device will attempt to connect again if it times out. |
| *blinkupBehavior*   | BLINK_ON_DISCONNECT | See below |
| *checkTimeout*      | 5                   | Changes how often the ConnectionManager checks the connection state (online / offline). |
| *connectTimeout*    | 60                  | Float. Maximum time (in seconds) allowed for the imp to connect to the server before timing out. |
| *errorPolicy*       | RETURN_ON_ERROR     | The disconnection handling policy: either SUSPEND_ON_ERROR, RETURN_ON_ERROR or RETURN_ON_ERROR_NO_DISCONNECT. |
| *waitPolicy*        | WAIT_TIL_SENT       | The successful transmission criterion: either WAIT_TIL_SENT or WAIT_FOR_ACK. |
| *ackTimeout*        | 1                   | Float. Maximum time (in seconds) allowed for the server to acknowledge receipt of data. |

```squirrel
#require "ConnectionManager.lib.nut:3.0.0"

// Instantiate ConnectionManager so BlinkUp is always enabled,
// and we automatically agressively try to reconnect on disconnect
cm <- ConnectionManager({
    "blinkupBehavior": ConnectionManager.BLINK_ALWAYS,
    "stayConnected": true
});

// Set the recommended buffer size (see note below)
imp.setsendbuffersize(8096);
```

**Note** We’ve found setting the buffer size to 8096 to be very helpful in many applications using the ConnectionManager class, though your application may require a different buffer size.
#### startBehavior
The startBehavior flag modifies what action the ConnectionManager takes when initialized.
- *CM_START_NO_ACTION* will take no action after being initialized. This is the default value.
- *CM_START_CONNECTED* will try to connect after being initialized.
- *CM_START_DISCONNECTED* will disconnect after being initialized.

#### blinkupBehavior

The blinkupBehavior flag modifies when the ConnectionManager enables the BlinkUp circuit (using [**imp.enableblinkup()**](http://electricimp.com/docs/api/imp/enableblinkup):

- *CM_BLINK_ON_DISCONNECT* will enable BlinkUp while the imp is disconnected. This is the default value.
- *CM_BLINK_ON_CONNECT* will enable BlinkUp while the imp is connected.
- *CM_BLINK_ALWAYS* will ensure the BlinkUp circuit is always active.
- *CM_BLINK_NEVER* will ensure the BlinkUp circuit is never active.

**Note** impOS&trade; *always* enables the BlinkUp circuit for the first 60 seconds after a cold boot to ensure the imp never enters an unrecoverable state. As a result, regardless of what *blinkupBehavior* flag is set, the imp will enable the BlinkUp circuit for 60 seconds after a cold boot.

#### ackTimeout

This value is passed into the imp API method [**server.setsendtimeoutpolicy()**](https://electricimp.com/docs/api/server/setsendtimeoutpolicy/), overriding any value your code may have already set in a separate call to that method (or overridden by a subsequent call your code makes). We recommend that if you make use of ConnectionManager, you ensure that you **never** call [**server.setsendtimeoutpolicy()**](https://electricimp.com/docs/api/server/setsendtimeoutpolicy/) in your application code.


## Class Methods

### setBlinkUpBehavior(*blinkupBehaviorFlag*)

The *setBlinkUpBehavior()* method changes the class’ BlinkUp behavior (see [blinkupBehavior flags](#blinkupbehavior), above).

```squirrel
// Set ConnectionManager to enable BlinkUp only while it's connected
cm.setBlinkUpBehavior(ConnectionManager.BLINK_ON_CONNECT);
```

### isConnected()

The *isConnected()* method returns the value of ConnectionManager’s internal connected state flag (whether or not we are connected). This flag is updated every five seconds, or as set by the *checkTimeout* setting in the constructor.

```squirrel
if (!cm.isConnected()) {
    // If we're not connected, gather some data, then connect
    cm.onNextConnect(function() {
        local data = sensor.read();
        agent.send("data", data);
    }).connect();
}
```

### onDisconnect(*callback*)

The *onDisconnect()* method assigns a callback function to the onDisconnect event. The onDisconnect event will fire every time the connection state changes from online to offline, or when the ConnectionManager’s *disconnect()* method is called (even if the device is already disconnected).

The callback method takes a single parameter, *expected*, which is `true` when the onDisconnect event fired due to the ConnectionManager’s disconnect method being called, and `false` otherwise (an unexpected state change from connected to disconnected).

```squirrel
cm.onDisconnect(function(expected) {
    if (expected) {
        // log a regular message that we disconnected as expected
        cm.log("Expected Disconnect");
    } else {
        // log an error message that we unexpectedly disconnected
        cm.error("Unexpected Disconnect");
    }
});
```

### onConnect(*callback*)

The *onConnect()* method assigns a callback method to the onConnect event. The onConnect event will fire every time the connection state changes from offline to online, or when the ConnectionManager’s *connect()* method is called (even if the device is already connected).

The callback function has no parameters.

```squirrel
cm.onConnect(function() {
    // Send a message to the agent indicating that we're online
    agent.send("online", true);
});
```

### onTimeout(callback)

The *onTimeout* method assigns a callback method to the onTimeout event. The onTimeout event will fire every time the device attempts to connect but does not succeed.

*The callback method takes zero parameters.*

```squirrel
cm.onTimeout(function() {
    // Go to sleep for 10 minutes if the device fails to connect
    server.sleepfor(600);
});
```

### onNextConnect(*callback*)

The *onNextConnect()* method queues a task (the callback) to run the next time the device connects. If the imp is already connected, the callback will be invoked immediately.

There is no limit on the number of tasks that can be queued (excluding any memory or time restraints your application may have).

The callback function has no parameters.

```squirrel
function poll() {
    // Wakeup every 60 seconds and gather data
    imp.wakeup(60, poll);

    // Read the data, and insert the timestamp into the data table
    // (in this example, we assume sensor.read() returns a table)
    local data = sensor.read();
    data["ts"] <- time();

    // Send the data the next time we connect
    cm.onNextConnect(function() {
        agent.send("data", data);
    });
}
```

**Note** If the imp enters a deep sleep or performs a cold boot, the task queue will be cleared.

### connectFor(*callback*)

The *connectFor()* method tells the imp to connect, run the callback method, then disconnect when complete. If the imp is already connected, the callback will be invoked immediately, and the imp will disconnect upon completion.

The callback function has no parameters.

```squirrel
function poll() {
    // Wakeup every 60 seconds, connect, send data, and disconnect
    imp.wakeup(60, poll);

    cm.connectFor(function() {
        // Read and send the data
        local data = sensor.read();
        data["ts"] <- time();
        agent.send("data", data);
    });
}
```

**Note** The *connectFor()* method is equivalent to:

```squirrel
cm.onNextConnect(function() {
    // Do something
    ...

    cm.disconnect();
}).connect();
```

### connect()

The *connect()* method tells ConnectionManager to attempt to connect to the server. If it successfully connects (or is already connected), ConnectionManager will execute the registered onConnect callback, perform any tasks queued from onNextConnect, and log all offline log messages (from *ConnectionManager.log()* and *ConnectionManager.error()*).

If a connect is already in process, the connect method will return `false` and won’t attempt to connect or invoke any callbacks, otherwise it returns `true`.

```squirrel
cm.connect();
```

### disconnect()

The *disconnect()* method tells ConnectionManager to attempt to disconnect from the server.
If it successfully disconnects (or is already disconnected), the ConnectionManager will execute
the registered onDisconnect callback, if there is one.

If a connect is in process, the disconnect method will return `false` and won’t attempt to
disconnect or invoke any callbacks, otherwise it returns `true`.

`force` parameter specifies whether the library should disconnect regarding of the connect status
(whether it's in progress or not). The parameter is optional and is `false` by default.

`flushTimeout` parameter specifies the timeout value used for `server.flush` call. The parameter is
optional and is equal to `CM_FLUSH_TIMEOUT` (30 seconds) by default.

```
cm.disconnect();
```

### log(*message*)

The *log()* method will execute a [**server.log()**](/docs/api/server/log/) command (if connected), or queue the value of *message* to be logged on the next connect. Any object that can be passed to [**server.log()**](/docs/api/server/log/) can be passed to *log()*.

**Note** The ConnectionManager class stores log messages in memory but doesn’t persist log messages across deep sleeps and cold boots.

```squirrel
cm.onDisconnect(function(expected) {
    if (expected) {
        // Log a regular message that we disconnected as expected
        cm.log("Expected Disconnect");
    } else {
        // Log an error message that we unexpectedly disconnected
        cm.error("Unexpected Disconnect");
    }
});
```

### error(*message*)

The *error()* method will execute a [**server.error()**](/docs/api/server/error/) command (if connected), or queue the value of *errorMessage* to be logged on the next connect. Any object that can be passed to [**server.error()**](/docs/api/server/error/) can be passed to *error()*.

**Note** The ConnectionManager class stores log messages in memory but doesn’t persist log messages across deep sleeps and cold boots.

See *log()*, above, for example code.

## License

The ConnectionManager class is licensed under the [MIT License](https://github.com/electricimp/ConnectionManager/blob/master/LICENSE).


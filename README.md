# ConnectionManager 1.0.0

The ConnectionManager class is an Electric Imp device side library aimed at simplifying connect and disconnect flows.

**NOTE:** If you are using the ConnectionManager class in your model, you should ensure that you are *never* calling `server.connect` or `server.disconnect` in your application code (instead you should use the ConnectionManager's `connect` and `disconnect` methods).

**To add this library to your project, add `#require "ConnectionManager.class.nut:1.0.0"` to the top of your device code.**

You can view the library's source code on [GitHub](https://github.com/electricimp/connectionmanager/tree/v1.0.0).

## Class Usage

### Constructor: ConnectionManager(*[settings]*)

The ConnectionManager class can be instantiated with an optional table of settings that modify it's behaviour. The following settings are available: 

| key               | default             | notes |
| ----------------- | ------------------- | ----- |
| startDisconnected | `false`             | When set to `true` the device immediately disconnects |
| stayConnected     | `false`             | When set to `true` the device will aggressively attempt to reconnect when disconnected |
| blinkupBehaviour  | BLINK_ON_DISCONNECT | See below |
| checkTimeout      | 5                   | Changes how often the ConnectionManager checks the connection state (online / offline). |

```squirrel
#require "ConnectionManager.class.nut:1.0.0"

// Instantiate ConnectionManager so BlinkUp is always enabled,
// and we automatically agressively try to reconnect on disconnect
cm <- ConnectionManager({
    "blinkupBehavior": ConnectionManager.BLINK_ALWAYS,
    "stayConnected": true
});
```

#### blinkupBehaviour

**Default Value:** `ConnectionManager.BLINK_ON_DISCONNECT`
**Values:** `BLINK_ON_DISCONNECT` | `BLINK_ON_CONNECT` | `BLINK_ALWAYS` | `BLINK_NEVER`

The blinkupBehaviour flag modifies when the ConnectionManager enables the BlinkUp circuit (using [imp.enableblinkup](http://electricimp.com/docs/api/imp/enableblinkup):

- `ConnectionManager.BLINK_ON_DISCONNECT` will enable BlinkUp while the imp is disconnected.
- `ConnectionManager.BLINK_ON_CONNECT` will enable BlinkUp while the imp is connected.
- `ConnectionManager.BLINK_ALWAYS` will ensure the BlinkUp circuit is always active.
- `ConnectionManager.BLINK_NEVER` will ensure the BlinkUp circuit is never active.

**NOTE:** The impOS **always** enables the BlinkUp circuit for the first 60 seconds after a coldboot to ensure the imp never enters an unrecoverable state. As a result, regardless of what blinkupBehavior flag is set, the imp will enable the BlinkUp circuit for 60 seconds after a coldboot.

## Class Methods

## setBlinkUpBehavior(blinkupBehaviorFlag)

The *setBlinkUpBehavior* method changes the class' BlinkUp behavior (see blinkupBehavior flags above).

```squirrel
// Set ConnectionManager to enable BlinkUp only while it's connected
cm.setBlinkUpBehavior(ConnectionManager.BLINK_ON_CONNECT);
```

## isConnected()

The *isConnected* method returns the value of ConnectionManager's internal connected state flag (whether or not we are connected). This flag is updated every 5 seconds (or as set by the `checkTimeout` flag in the constructor).

```squirrel
if (!cm.isConnection()) {
    // If we're not connected, gather some data, then connect
    cm.onNextConnect(function() {
        local data = sensor.read();
        agent.send("data", data);
    }).connect();
}
```

## onDisconnect(callback)

The *onDisconnect* method assigns a callback method to the onDisconnect event. The onDisconnect event will fire every time the connection state changes from online to offline, or when the ConnectionManager's *disconnect* method is called (even if the device is already disconnected).

*The callback method takes a single parameter - `expected` - which is `true`when the onDisconnect event fired due to the ConnectionManager's disconnect method being called, and `false` otherwise (an unexpected state change from connected to disconnected).*

```squirrel
cm.onDisconnect(function(expected) {
    if (expected) {
        // log a regular message taht we disconnected as expected
        cm.log("Expected Disconnected");
    } else {
        // log an error message that we unexpectedly disconnected
        cm.error("Unexpected Disconnect");
    }
});
```

## onConnect(callback)

The *onConnect* method assigns a callback method to the onConnect event. The onConnect event will fire every time the connection state changes from offline to online, or when the ConnectionManager's *connect* method is called (even if the device is already connected).

*The callback method takes zero parameters.*

```squirrel
cm.onConnect(function() {
    // Send a message to the agent indicating that we're online
    agent.send("online", true);
});
```

## onNextConnect(callback)

The *onNextConnect* method queues a task (the callback) to run the next time the device connects. If the imp is already connected, the callback will be invoked immediately.

*The callback method takes zero parameters.*

```squirrel
function poll() {
    // Wakeup every 60 seconds and gather data
    imp.wakeup(60, poll);

    // Read the data, and insert the timestamp into the data table
    local data = sensor.read();
    data["ts"] <- time();

    // Send the data the next time we connect
    cm.onNextConnect(function() {
        agent.send("data", data);
    });
}
```

**NOTE**: If the imp enters a deepsleep, the task queue is cleared.

## connectFor(callback)

The *connectFor* method tells the imp to connect, run the callback method, then disconnect when complete. If the imp is already connected, the callback will be invoked immediately (and the imp will disconnect upon completion).

*The callback method takes zero parameters.*

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

**NOTE:** The connectFor method is equivalent to:

```squirrel
cm.onNextConnect(function() {
    // do something
    ...

    cm.disconnect();
}).connect();
```

## connect()

The *connect* method tells the ConnectionManager to attempt to connect to the server. If it successfully connects (or is already connected), the ConnectionManager will execute the *ConnectionManager.onConnect* callback, any tasks queued from onNextConnect, as well as log all offline log messages (from ConnectionManager.log and ConnectionManager.error).

If a connect is already in process, the connect method will return `false` (and won't attempt to connect or invoke any callbacks), otherwise it returns `true`.

```squirrel
cm.connect();
```

## disconnect()

The *disconnect* method tells the ConnectionManager to attempt to disconnect from the server. If it successfully disconnects (or is already disconnected), the ConnectionManager will execute the *ConnectionManager.onDisconnect* callback.

If a connect is in process, the disconnect method will return `false` (and won't attempt to disconnect or invoke any callbacks), otherwise it returns `true`.

```
cm.disconnect();
```

## log(message)

The *log* method will execute a `server.log` command (if connected), or queue the message to be logged on the next connect. Any object that can be passed to `server.log` can be passed to *ConnectionManager.log*.

```squirrel
cm.onDisconnect(function(expected) {
    if (expected) {
        // log a regular message taht we disconnected as expected
        cm.log("Expected Disconnected");
    } else {
        // log an error message that we unexpectedly disconnected
        cm.error("Unexpected Disconnect");
    }
});
```

## error(message)

The *log* method will execute a `server.error` command (if connected), or queue the message to be logged (as an error) on the next connect. Any object that can be passed to `server.error` can be passed to ConnectionManager.error.

*See log(message) for example.*

# License

The ConnectionManager class is licensed under the [MIT License](https://github.com/electricimp/ConnectionManager/blob/master/LICENSE).


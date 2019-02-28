# ConnectionManager 3.1.1 #

The ConnectionManager class is an Electric Imp device-side library created to simplify connect and disconnect flows.

**Note** If you are using ConnectionManager in your code, you should ensure that you *never* call [**server.connect()**](https://developer.electricimp.com/api/server/connect) or [**server.disconnect()**](https://developer.electricimp.com/api/server/disconnect). Instead you should only use ConnectionManager’s [*connect()*](#connect) and [*disconnect()*](#disconnectforce-flushtimeout) methods.

**To include this library in your project, add** `#require "ConnectionManager.lib.nut:3.1.1"` **at the top of your device code.**

## Class Usage ##

### Constructor: ConnectionManager(*[settings]*) ###

ConnectionManager can be instantiated with an optional table of settings that modify its behavior. The following settings are available:

| Key | Required? | Description |
| --- | --- | --- |
| *startBehavior* | No | See below. Default: *CM_START_NO_ACTION* |
| *stayConnected* | No | When set to `true`, the device will aggressively attempt to reconnect when disconnected. Default: `false` |
| *retryOnTimeout* | No | When set to `true`, the device will attempt to connect again if it times out. Default: `true` |
| *blinkupBehavior* | No | See below. Default: *CM_BLINK_ON_DISCONNECT* |
| *checkTimeout* | No | Changes how often the ConnectionManager checks the connection state (online/offline. Default: 5 |
| *connectTimeout* | No | Maximum time (in seconds) allowed for the imp to connect to the server before timing out. Default: 60.0 |
| *errorPolicy* | No | The disconnection handling policy: *SUSPEND_ON_ERROR*, *RETURN_ON_ERROR or *RETURN_ON_ERROR_NO_DISCONNECT*. Default: *RETURN_ON_ERROR* |
| *waitPolicy* | No | The successful transmission criterion: either *WAIT_TIL_SENT* or *WAIT_FOR_ACK*. Default: *WAIT_TIL_SENT* |
| *ackTimeout* | No | The maximum time (in seconds) allowed for the server to acknowledge receipt of data. Default: 1.0 |

#### Example ####

```squirrel
#require "ConnectionManager.lib.nut:3.1.1"

// Instantiate ConnectionManager so BlinkUp is always enabled,
// and we automatically aggressively try to reconnect on disconnect
cm <- ConnectionManager({ "blinkupBehavior": CM_BLINK_ALWAYS,
                          "stayConnected"  : true });

// Set the recommended buffer size (see note below)
imp.setsendbuffersize(8096);
```

**Note** We’ve found setting the buffer size to 8096 to be very helpful in many applications using ConnectionManager, though your application may require a different buffer size.

#### Setting: startBehavior ####

The *startBehavior* flag modifies what action ConnectionManager takes when initialized:

- *CM_START_NO_ACTION* will take no action after being initialized. This is the default value.
- *CM_START_CONNECTED* will try to connect after being initialized.
- *CM_START_DISCONNECTED* will disconnect after being initialized.

#### Setting: blinkupBehavior ####

The *blinkupBehavior* flag modifies when ConnectionManager enables the BlinkUp™ circuit (using [**imp.enableblinkup()**](https://developer.electricimp.com/api/imp/enableblinkup):

- *CM_BLINK_ON_DISCONNECT* will enable BlinkUp while the imp is disconnected. This is the default value.
- *CM_BLINK_ON_CONNECT* will enable BlinkUp while the imp is connected.
- *CM_BLINK_ALWAYS* will ensure the BlinkUp circuit is always active.
- *CM_BLINK_NEVER* will ensure the BlinkUp circuit is never active.

**Note** impOS™ *always* enables the BlinkUp circuit for the first 60 seconds after a cold boot to ensure the imp never enters an unrecoverable state. As a result, regardless of what *blinkupBehavior* flag is set, the imp will enable the BlinkUp circuit for 60 seconds after a cold boot.

#### Setting: ackTimeout ####

This value is passed into the imp API method [**server.setsendtimeoutpolicy()**](https://developer.electricimp.com/api/server/setsendtimeoutpolicy), overriding any value your code may have already set in a separate call to that method (or overridden by a subsequent call your code makes). We recommend that if you make use of ConnectionManager, you ensure that you **never** call [**server.setsendtimeoutpolicy()**](https://developer.electricimp.com/api/server/setsendtimeoutpolicy) in your application code.

## Class Methods ##

### setBlinkUpBehavior(*blinkupBehaviorFlag*) ###

This method can be used to change the class’ BlinkUp behavior.

#### Parameters ####

[See above](#setting-blinkupbehavior).

#### Returns ####

Nothing.

#### Example ####

```squirrel
// Set ConnectionManager to enable BlinkUp only while it's connected
cm.setBlinkUpBehavior(CM_BLINK_ON_CONNECT);
```

### isConnected() ###

This method can be used to determine the value of ConnectionManager’s internal connection state flag (ie. whether or not the imp is connected). This flag is updated every five seconds, or as set by the *checkTimeout* setting in [the constructor](#constructor-connectionmanagersettings).

#### Returns ####

Boolean &mdash; `true` if the device is connected, otherwise `false`.

#### Example ####

```squirrel
if (!cm.isConnected()) {
    // If we're not connected, gather some data, then connect
    cm.onNextConnect(function() {
        local data = sensor.read();
        agent.send("data", data);
    }).connect();
}
```

### onDisconnect(*callback[, callbackID]*) ###

This method assigns a callback function to the onDisconnect event. The onDisconnect event will fire every time the connection state changes from online to offline, or when ConnectionManager’s [*disconnect()*](#disconnectforce-flushtimeout) method is called (even if the device is already disconnected).

ConnectionManager allows multiple onDisconnect callbacks to be registered. Each of the callbacks should have a unique string identifier passed into the second parameter, *callbackID*. If the *callbackID* parameter’s argument is not specified, a default value is used (`"DEFAULT_CB_ID"`). Calling *onDisconnect()* multiple times with the same or no *callbackID* overwrites the previously set callback.

Pass `null` into *callback* to clear the onDisconnect callback for the specified (or the default) callback ID.

#### Parameters ####

| Parameter | Data&nbsp;Type | Required | Description |
| --- | --- | --- | --- | 
| *callback* | Function | Yes | Called when ConnectionManager’s connection state changes from online to offline. See [below for details](#the-ondisconnect-callback) |
| *callbackID* | String | No | Optional identifier |

#### The onDisconnect Callback ####

The callback function has a single parameter, *expected*, which is `true` when the onDisconnect event fired due to *disconnect()* being called, and `false` otherwise (an unexpected state change from connected to disconnected).

#### Returns ####

Nothing.

#### Example ####

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

### onConnect(*callback[, callbackID]*) ###

This method assigns a callback function to the onConnect event. The onConnect event will fire every time the connection state changes from offline to online, or when ConnectionManager’s [*connect()*](#connect) method is called (even if the device is already connected).

ConnectionManager allows multiple onConnect callbacks to be registered. Each of the callbacks should have a unique string identifier passed into the second parameter, *callbackID*. If the *callbackID* parameter’s argument is not specified, a default value is used (`"DEFAULT_CB_ID"`). Calling *onConnect()* multiple times with the same or no *callbackId* overwrites the previously set callback.

Pass `null` into *callback* to clear the onConnect callback for the specified (or the default) callback ID.

#### Parameters ####

| Parameter | Data&nbsp;Type | Required | Description |
| --- | --- | --- | --- | 
| *callback* | Function | Yes | Called when ConnectionManager’s connection state changes from offline to online. The callback function has no parameters |
| *callbackID* | String | No | Optional identifier |

#### Returns ####

Nothing.

#### Example ####

```squirrel
cm.onConnect(function() {
    // Send a message to the agent indicating that we're online
    agent.send("online", true);
});
```

### onTimeout(*callback[, callbackID]*) ###

This method assigns a callback function to the onTimeout event. The onTimeout event will fire every time the device attempts to connect but does not succeed.

ConnectionManager allows multiple onTimeout callbacks to be registered. Each of the callbacks should have a unique string identifier passed into the second parameter, *callbackID*. If the *callbackID* parameter’s argument is not specified, a default value is used (`"DEFAULT_CB_ID"`). Calling *onTimeout()* multiple times with the same or no *callbackID* overwrites the previously set callback.

Pass `null` into *callback* to clear the onTimeout callback for the specified (or the default) callback ID.

#### Parameters ####

| Parameter | Data&nbsp;Type | Required | Description |
| --- | --- | --- | --- | 
| *callback* | Function | Yes | Called when the device attempts to connect but fails to do so. The callback function has no parameters |
| *callbackID* | String | No | Optional identifier |

#### Returns ####

Nothing.

#### Example ####

```squirrel
cm.onTimeout(function() {
    // Go to sleep for 10 minutes if the device fails to connect
    server.sleepfor(600);
});
```

### onNextConnect(*callback*) ###

This method queues a function to run the next time the device connects for whatever reason. If the device is already connected, the callback will be invoked immediately. There is no limit on the number of tasks that can be queued (excluding any memory or time restraints your application may have).

#### Parameters ####

| Parameter | Data&nbsp;Type | Required | Description |
| --- | --- | --- | --- | 
| *callback* | Function | Yes | Called when the device next connects, or is connected already. The callback function has no parameters |

#### Returns ####

Nothing.

#### Example ####

```squirrel
function poll() {
    // Wake up every 60 seconds and gather data
    imp.wakeup(60, poll);

    // Read the data, and insert the timestamp into the data table
    // (in this example, we assume sensor.read() returns a table)
    local data = sensor.read();
    data.ts <- time();

    // Send the data the next time we connect
    cm.onNextConnect(function() {
        agent.send("data", data);
    });
}
```

**Note** If the imp enters a deep sleep or performs a cold boot, the task queue will be cleared.

### connectFor(*callback*) ###

This method tells the device to connect, run the supplied callback function, and then disconnect when complete. If the device is already connected, the callback will be invoked immediately, and the device will disconnect upon completion.

#### Parameters ####

| Parameter | Data&nbsp;Type | Required | Description |
| --- | --- | --- | --- | 
| *callback* | Function | Yes | Called when the device has connected, or is connected already. The callback function has no parameters |

#### Returns ####

Nothing.

#### Example ####

```squirrel
function poll() {
    // Wake up every 60 seconds, connect, send data and disconnect
    imp.wakeup(60, poll);

    cm.connectFor(function() {
        // Read and send the data
        local data = sensor.read();
        data.ts <- time();
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

### connect() ###

This method tells ConnectionManager to attempt to connect to the server. If it successfully connects (or is already connected), ConnectionManager will execute any registered [onConnect callback](#onconnectcallback-callbackid), perform any tasks queued from [onNextConnect](#onnextconnectcallback), and log all offline log messages (from [*log()*](#logmessage) and [*error()*](#errormessage)).

If a connection attempt is already in process, *connect()* will not attempt to connect or invoke any callbacks.

#### Returns ####

Boolean &mdash; `true` if ConnectionManager is now attempting to connect, or `false` if a connection attempt is already in process.

#### Example ####

```squirrel
cm.connect();
```

### disconnect(*[force][, flushTimeout]*) ###

This method tells ConnectionManager to attempt to disconnect from the server. If it successfully disconnects (or is already disconnected), the ConnectionManager will execute the registered [onDisconnect callback](#ondisconnectcallback-callbackid), if there is one.

If a connection attempt is in process, *disconnect()* will not attempt to disconnect or invoke any callbacks.

#### Parameters ####

| Parameter | Data&nbsp;Type | Required | Description |
| --- | --- | --- | --- | 
| *force* | Boolean | No | Force ConnectionManager to disconnect regardless of the connection status (ie. whether it’s in progress or not). Default: `false` |
| *flushTimeout* | Integer or float | No | The timeout value used for [**server.flush()**](https://developer.electricimp.com/api/server/flush) calls. If set to -1, no flush is performed. Default: *CM_FLUSH_TIMEOUT* (30 seconds) |

#### Returns ####

Boolean &mdash; `true` if ConnectionManager is now attempting to disconnect, otherwise `false`.

#### Example ####

```squirrel
cm.disconnect();
```

### log(*message*) ###

This method will execute a [**server.log()**](https://developer.electricimp.com/api/server/log) command (if connected), or queue the value of *message* to be logged on the next connect. Any object that can be passed to [**server.log()**](https://developer.electricimp.com/api/server/log) can be passed to *log()*.

**Note** ConnectionManager stores log messages in memory but doesn’t persist them across deep sleeps and cold boots.

#### Returns ####

Nothing.

#### Example ####

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

### error(*message*) ###

The *error()* method will execute a [**server.error()**](https://developer.electricimp.com/api/server/error) command (if connected), or queue the value of *errorMessage* to be logged on the next connect. Any object that can be passed to [**server.error()**](https://developer.electricimp.com/api/server/error) can be passed to *error()*.

**Note** ConnectionManager stores error messages in memory but doesn’t persist them across deep sleeps and cold boots.

#### Returns ####

Nothing.

#### Example ####

See [*log()*](#logmessage), above, for example code.

## Running Tests ##

Some tests change the test device’s WiFi configuration. To ensure that the test device’s WiFi settings are restored after the test run, you should set the environment variables *CM_TEST_SSID* and *CM_TEST_PWD* to the required WiFi SSID and password, respectively.

Alternatively, you can create an `.imptest-builder` file with *CM_TEST_SSID* and *CM_TEST_PWD* defined within it. For example:

```JSON
{ "CM_TEST_SSID": "<YOUR_WIFI_SSID>",
  "CM_TEST_PWD" : "<YOUR_WIFI_PASSWORD>" }
``` 

## License ##

This library is licensed under the [MIT License](https://github.com/electricimp/ConnectionManager/blob/master/LICENSE).
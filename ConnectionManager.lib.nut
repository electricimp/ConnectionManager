// MIT License

// Copyright 2015-2017 Electric Imp

// SPDX-License-Identifier: MIT

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.


class ConnectionManager {
    static VERSION = "2.1.0";

    static BLINK_ALWAYS = 0;
    static BLINK_NEVER = 1;
    static BLINK_ON_CONNECT = 2;
    static BLINK_ON_DISCONNECT = 3;
    static FLUSH_TIMEOUT = 30;
    static START_NO_ACTION = 0;
    static START_CONNECTED = 1;
    static START_DISCONNECTED = 2;

    // Settings
    _connectTimeout = null;
    _checkTimeout = null;
    _stayConnected = null;
    _blinkupBehavior = null;
    _retryOnTimeout = null;

    // Global Handlers
    _onConnect = null;
    _onTimeout = null;
    _onDisconnect = null;

    // Connection State
    _connected = null;
    _connecting = null;

    // The onConnected task queue and logs
    _queue = null;
    _logs = null;

    constructor(settings = {}) {
        // Grab settings
        _checkTimeout       = ("checkTimeout"    in settings) ? settings.checkTimeout    : 5;
        _connectTimeout     = ("connectTimeout"  in settings) ? settings.connectTimeout  : 60;
        _stayConnected      = ("stayConnected"   in settings) ? settings.stayConnected   : false;
        _blinkupBehavior    = ("blinkupBehavior" in settings) ? settings.blinkupBehavior : BLINK_ON_DISCONNECT;
        _retryOnTimeout     = ("retryOnTimeout"  in settings) ? settings.retryOnTimeout  : true;
        local startBehavior = ("startBehavior"   in settings) ? settings.startBehavior   : START_NO_ACTION;
        local errorPolicy   = ("errorPolicy"     in settings) ? settings.errorPolicy     : RETURN_ON_ERROR;
        local waitPolicy    = ("waitPolicy"      in settings) ? settings.waitPolicy      : WAIT_TIL_SENT;
        local ackTimeout    = ("ackTimeout"      in settings) ? settings.ackTimeout      : 1;

        // Initialize the onConnected task queue and logs
        _queue = [];
        _logs = [];

        // Set the timeout policy + disconnect if required
        server.error("errorPolicy: " + errorPolicy);
        server.setsendtimeoutpolicy(errorPolicy, waitPolicy, ackTimeout);

        switch (startBehavior) {
            case START_NO_ACTION:
                // Do nothing
                break;
            case START_CONNECTED:
                // Start connecting if they ask for it
                imp.wakeup(0, connect.bindenv(this));
                break;
            case START_DISCONNECTED:
                // Disconnect if required
                imp.wakeup(0, disconnect.bindenv(this));
                break;
        }

        // Get the initial state and set BlinkUp accordingly
        _setBlinkUpState();

        // Start the watchdog
        _watchdog();

    }

    // Sets an onConnect handler that fires everytime we connect. Passing
    // null to this function removes the onConnect handler
    //
    // Parameters:
    //      callback:   The onConnect handler (no parameters)
    //
    // Returns:         this
    function onConnect(callback) {
        _onConnect = callback;

        return this;
    }

    // Sets an onTimeout handler that fires when a connection attempt fails. Passing
    // null to this function removes the onTimeout handler
    //
    // Parameters:
    //      callback:   The onTimeout handler (no parameters)
    //
    // Returns:         this
    function onTimeout(callback) {
        _onTimeout = callback;

        return this;
    }

    // Sets a onDisconnect handler that fires everytime we disconnect. Passing
    // null to this function removes the onDisconnect handler
    //
    // Parameters:
    //      callback:   The onDisconnectHandler with 1 parameter:
    //        expected    True - when onDisconnect was called because of a disconnect()
    //                    False - otherwise
    //
    // Returns:         this
    function onDisconnect(callback) {
        _onDisconnect = callback;

        return this;
    }

    // Returns the ConnectionManager's view of if we're connected or not
    function isConnected() {
        return _connected;
    }

    // Attempts to connect. If the server is already connected, or the
    // connection attempt was successful, run the onConnect handler, and
    // any other onConnected tasks
    function connect() {

        // If we're connecting/disconnecting, try again in 0.5 seconds
        if (_connecting) return false;

        // If we're already connected: invoke the onConnectedFlow and return
        if (_connected) {
            _onConnectedFlow();
            return true;
        }

        // Otherwise, try to connect...

        // Set the _connecting flag at the start
        _connecting = hardware.millis();
        server.connect(function(result) {

            // clear connecting flag when we're done trying to connect
            _connecting = false;
            if (result == SERVER_CONNECTED) {
                // If it worked, run the onConnectedFlow
                _connected = true;
                _onConnectedFlow();
            } else {
                // Otherwise, restart the connection process
                _onTimeoutFlow();
            }
        }.bindenv(this), _connectTimeout);

        // Catch a race condition where server.connect() won't throw the callback if its already connected
        if (server.isconnected()) {
            _connecting = false;
            _connected = true;
            _onConnectedFlow();
        }

        return true;
    }

    // Disconnects, and runs the onDisconnected handler
    function disconnect() {
        // If we're connecting / disconnecting, try again in 0.5 seconds
        if (_connecting) { return false; }

        // If we're already disconnected: invoke the onDisconnectedFlow and return
        if (!_connected) {
            _onDisconnectedFlow(true);
            return true;
        }

        // Disconnect
        server.flush(FLUSH_TIMEOUT);
        server.disconnect();

        // Set the flag
        _connected = false;

        // Run the onDisconnectedFlow
        _onDisconnectedFlow(true);

        return true;
    }

    // Pushes a task onto the onConnected task queue that will
    // be executed the next time the device connects. if the device
    // is already connected, it will be executed immediatly
    //
    // Parameters:
    //      callback    The task to execute
    //
    // Returns:         this
    function onNextConnect(callback) {
        _queue.push(callback);
        _processQueue();
        return this;
    }

    // Queues the callback to run on next connect, then connects,
    // runs all queued tasks and disconnects
    function connectFor(callback) {
        local cb = _connectForCallbackFactory(callback);
        _queue.push(cb);
        connect();
    }

    // Sets the BlinkUp behavior to one of the preconfigured options
    //
    // Parameters:
    //      state:      BLINK_ALWAYS | BLINK_NEVER | BLINK_ON_CONNECT | BLINK_ON_DISCONNECT
    //
    // Returns:         this
    function setBlinkUpBehavior(state) {
        _blinkupBehavior = state;
        _setBlinkUpState();

        return this;
    }

    function log(obj, error = false) {
        if (_connected) {
            if (error) {
                server.error(obj.tostring());
            } else {
                server.log(obj.tostring());
            }
        } else {
            _logs.push({ "ts": time(), "error": error, "log": obj.tostring() });
        }
    }

    function error(obj) {
        log(obj, true);
    }

    //-------------------- PRIVATE METHODS --------------------//

    // Wraps a callback function so it executes, then immediatly
    // disconnects.
    function _connectForCallbackFactory(callback) {
        return function() {
            callback();
            disconnect();
        }.bindenv(this);
    }

    // Watches for changes in connection state, and invokes the
    // onConnectedFlow and onDisconnectedFlow where appropriate
    function _watchdog() {

        // Schedule _watchdog to run again
        imp.wakeup(_checkTimeout, _watchdog.bindenv(this));

        // Don't do anything if we're connecting (unless there is a timeout of course)
        if (_connecting) {
            if (hardware.millis() - _connecting > (_connectTimeout*1000)) {
                _onTimeoutFlow()
            }
            return;
        }

        // Check if we're connected
        local connected = server.isconnected()

        // If the state hasn't changed, we're done
        if (_connected == connected) return;

        // Set the new connected state
        _connected = connected;

        // Run the appropriate flow
        if (connected) {
            _onConnectedFlow();
        } else {
            _onDisconnectedFlow(false);
        }
    }

    // Runs whenever we connect or call connect()
    function _onConnectedFlow() {

        // Set the BlinkUp State
        _setBlinkUpState();

        while(_logs.len() > 0) {
            local log = _logs.remove(0);
            if (!log.error) {
                server.log(log.ts + " - " + log.log)
            } else {
                server.error(log.ts + " - " + log.log)
            }
        }

        // Run the global onConnected Handler if it exists
        if (_onConnect != null) {
            imp.wakeup(0, function() { _onConnect(); }.bindenv(this));
        }

        _processQueue();
    }

    // Runs whenever we disconnect, or call disconnect()
    function _onDisconnectedFlow(expected) {

        // Set the BlinkUp State
        _setBlinkUpState();

        // Run the global onDisconnected Handler if it exists
        if (_onDisconnect != null) {
            imp.wakeup(0, function() { _onDisconnect(expected); }.bindenv(this));
        }

        if (_stayConnected) {
            imp.wakeup(0, connect.bindenv(this));
        } else {
            // Brutally stop trying to connect
            server.disconnect();
        }
    }


    // Runs whenever a call to connect times out
    function _onTimeoutFlow() {

        // Set the BlinkUp State
        _setBlinkUpState();

        _connecting = false;
        _connected = false;
        if (_onTimeout != null) {
            imp.wakeup(0, function() { _onTimeout(); }.bindenv(this));
        }

        if (_retryOnTimeout) {
            // We have a timeout trying to connect. We need to retry;
            imp.wakeup(0, connect.bindenv(this));
        }
    }


    // Helper function for _onConnectedFlow that processes all the tasks
    // in the onConnected _queue or quits once we're no longer connected
    function _processQueue() {
        // If we're done, are connecting/disconnecting, or are disconnected
        if (_queue.len() == 0 || _connecting || !_connected) return;

        local cb = _queue.remove(0);
        imp.wakeup(0, function() {
            // Invoke the next queued task
            cb();
            // Do it again!!
            _processQueue();
        }.bindenv(this));
    }

    // Enables of disables BlinkUp based on _blinkupBehavior and _connected
    function _setBlinkUpState() {
        // If it's set to always blinkup
        if (_blinkupBehavior == BLINK_ALWAYS) {
            imp.enableblinkup(true);
            return;
        }
        // If it's set to never blinkup
        if (_blinkupBehavior == BLINK_NEVER) {
            imp.enableblinkup(false);
            return;
        }

        // If it's set to blinkup on a specific state
        if ((_connected && _blinkupBehavior == BLINK_ON_CONNECT)
        || (!_connected && _blinkupBehavior == BLINK_ON_DISCONNECT)) {
            imp.enableblinkup(true);
        } else {
            imp.enableblinkup(false);
        }
    }
}

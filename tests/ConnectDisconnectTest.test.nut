// MIT License
//
// Copyright 2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

@include "./ConnectionManager.lib.nut"
@include "./tests/CommonTest.nut"

class ConnectDisconnectTest extends CommonTest {

    function setUp() {
        _setUp();
    }
    
    /*
    * disconnects and connects device using CM
    *
    */
    function testSingleConnectDisconnectCMAsync() {
        return Promise(function(resolve, reject) {
            _cm.onDisconnect(function(expected) {
                assertTrue(!server.isconnected(), "should NOT be connected!");
                assertTrue(!_cm.isConnected(), "CM should NOT report connected state!");
                _cm.connect();
            }.bindenv(this));

            _cm.onConnect(function() {
                resolve();
            }.bindenv(this));

            _disconnectAndCheck();
        }.bindenv(this))
        .then(_commonThenStep.bindenv(this))
        .fail(_commonFailStep.bindenv(this));
    }

    /*
    * Verifies that more than one disconnect() invocation doesn't result in incorect behavior
    *
    */
    function testDoubleDisconnectAsync() {
        assertTrue(server.isconnected(), "Failed pre-run sanity check");
        return Promise(function(resolve, reject) {
            _cm.onDisconnect(function(expected) {
                assertTrue(!server.isconnected(), "should NOT be connected!");
                assertTrue(!_cm.isConnected(), "CM should NOT report connected state!");
                _cm.connect();
            }.bindenv(this));

            _disconnectAndCheck();

            _cm.onConnect(function() {
                resolve();
            }.bindenv(this));

            _disconnectAndCheck();
        }.bindenv(this))
        .then(_commonThenStep.bindenv(this))
        .fail(_commonFailStep.bindenv(this));
    }

    /*
    * Verifies that more than one connect() invocation doesn't lead to disconnection
    *
    */
    function testDoubleConnectAsync() {
        assertTrue(server.isconnected(), "Failed pre-run sanity check");
        return Promise(function(resolve, reject) {
            _cm.connect();
            assertTrue(server.isconnected(), "should be connected!");
            assertTrue(_cm.isConnected(), "CM should report connected state!");

            _cm.onConnect(function() {
                assertTrue(server.isconnected(), "should be connected!");
                assertTrue(_cm.isConnected(), "CM should report connected state!");
                resolve();
            }.bindenv(this));

            _cm.connect();
            assertTrue(server.isconnected(), "should be connected!");
            assertTrue(_cm.isConnected(), "CM should report connected state!");
        }.bindenv(this))
        .then(_commonThenStep.bindenv(this))
        .fail(_commonFailStep.bindenv(this));
    }

    /*
    * sets connectFor callback
    *
    */
    function testConnectForAsync() {
        return _checkConnectForCommon();
    }

    /*
    * sets connectFor callback calls _cm.disconnect before
    *
    */
    function testConnectForFromDisconnectedStateAsync() {
        return _checkConnectForCommon(true);
    }

    function tearDown() {
        _resetCM();
        return "Test finished";
    }

    //-------------------- PRIVATE METHODS --------------------//

    function _checkConnectForCommon(needDisconnect = false) {
        local counter = 0;
        assertTrue(server.isconnected(), "Failed pre-run sanity check");
        if (needDisconnect) {
            _cm.disconnect();
            assertTrue(!server.isconnected(), "should NOT be connected!");
        }
        return Promise(function(resolve, reject) {
            _cm.onDisconnect(function(expected) {
                assertTrue(!_cm.isConnected(), "should NOT be connected!");
                assertTrue(!server.isconnected(), "should NOT be connected!");

                _cm.onConnect(function() {
                    assertEqual(counter, 2, "counter should be 2 now");
                    counter++;
                    resolve();
                }.bindenv(this));
                counter++;
                _cm.connect();
            }.bindenv(this));

            _cm.connectFor(function() {
                assertTrue(server.isconnected(), "inside connectFor: should be connected!");
                counter++;
            }.bindenv(this));
        }.bindenv(this))
        .then(function(val) {
            assertEqual(counter, 3, "counter should be 3 now");
            _commonThenStep();
        }.bindenv(this))
        .fail(_commonFailStep.bindenv(this));
    }

    /*
    *disconnects device and cheks that it was actually disconnected
    *
    */
    function _disconnectAndCheck() {
        _cm.disconnect();
        assertTrue(!server.isconnected(), "should NOT be connected!");
        assertTrue(!_cm.isConnected(), "CM should NOT report connected state!");
    }

}
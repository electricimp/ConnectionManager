// MIT License
//
// Copyright 2017-2018 Electric Imp
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

class CallbacksTest extends CommonTest {

    function setUp() {
        _setUp();
    }
    
    /*
     * sets onDisconnect callback and disconnects device using CM
     *
     */
    function testOnDisconnectAsync() {
        return Promise(function(resolve, reject) {
            _cm.onDisconnect(function(expected) {
                _cm.connect();
            }.bindenv(this));

            _cm.onConnect(function() {
                resolve();
            }.bindenv(this));

            _cm.disconnect();
            assertTrue(!server.isconnected(), "should NOT be connected!");
        }.bindenv(this))
        .then(function(val) {
            assertTrue(server.isconnected(), "should be connected again!");
            _resetCM();
        }.bindenv(this))
        .fail(_commonFailStep.bindenv(this));
    }

    /*
     * sets onConnect callback and disconnects device using CM
     *
     */
    function testOnConnectAsync() {
        return Promise(function(resolve, reject) {
            local cCounter = 0;
            local dCounter = 0;
            _cm.onDisconnect(function(expected) {
                assertTrue(!cCounter, "should be 0 now");
                dCounter++;
                _cm.connect();
            }.bindenv(this));

            _cm.onConnect(function() {
                cCounter++;
                resolve([cCounter, dCounter]);
            }.bindenv(this));

            assertTrue(!cCounter, "cCounter should 0 before re-connect");
            assertTrue(!dCounter, "dCounter should 0 before disconnect");
            assertTrue(_cm.disconnect(), "Invalid cm.disconnect precondition");
            assertTrue(!server.isconnected(), "should NOT be connected!");
        }.bindenv(this))
        .then(function(val) {
            //not assertTrue(*Counter, ...) to ensure *Counter was increased exactly one time
            assertEqual(val[0], 1, "connected again, should be 1 now");
            assertEqual(val[1], 1, "connected again, should be 1 now");
            _resetCM();
        }.bindenv(this))
        .fail(_commonFailStep.bindenv(this));
    }

    /*
     * removes onConnect callback checks it is not firing any more
     *
     */
    function testOnConnectRemovalAsync() {
        return Promise(function(resolve, reject) {
            local counter = 0;
            _cm.onConnect(function() {
                counter++;
                //in case onConnect will be called twice, second time counter will become 2 and test fails
                assertEqual(counter, 1, "should be 1 now");
                resolve(counter);
            }.bindenv(this));

            //_cm.connect returns false iff it's already in process of connection
            assertTrue(_cm.connect(), "should NOT be connecting now");
        }.bindenv(this))
        .then(function(counter) {
            assertEqual(counter, 1, "should be 1 yet");
            _resetCM();
        }.bindenv(this))
        .fail(_commonFailStep.bindenv(this));
    }

    function tearDown() {
        _resetCM();
        return "Test finished";
    }

}
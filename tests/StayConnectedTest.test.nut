// MIT License
//
// Copyright 2018 Electric Imp
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

    ssid = "@{CM_TEST_SSID}";
    password = "@{CM_TEST_PWD}";

    function setUp() {
        info("running setUp");
        _cm = ConnectionManager({
            "blinkupBehavior": CM_BLINK_ALWAYS,
            "connectTimeout": 10,
            "stayConnected": true
        });
    }
    
    /*
     * disconnects device using CM, awaiting autoconnect
     * after wifi config is set.
     */
    function testAutoreconnectAsync() {

        return Promise(function(resolve, reject) {
            // pass test when CM reconnected
            _cm.onConnect(function() {
                resolve();
            }.bindenv(this));
            assertTrue(((ssid != "null") && (ssid != "")),  "WiFi configuration should be set for this test");

            // delete ssid and password
            imp.clearconfiguration(CONFIG_WIFI);
            _cm.disconnect(true, 5);

            // wait 20 seconds to ensure CM tries to reconnect
            imp.wakeup(20, function () {
                assertTrue(!_cm.isConnected(), "CM should NOT report connected state!");

                // reset WiFi settings, now CM should reconnect 
                imp.setwificonfiguration(ssid, password);
            }.bindenv(this));
        }.bindenv(this))
        .then(_commonThenStep.bindenv(this))
        .fail(_commonFailStep.bindenv(this));
    }

    function tearDown() {
        _resetCM();
        return "Test finished";
    }
}
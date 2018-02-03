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

class StayConnectedTest extends CommonTest {

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
    function testStayConnectedAsync() {

        return Promise(function(resolve, reject) {
            assertTrue(_cm.isConnected(), "CM should report connected state!")

            local ssid = "@{CM_TEST_SSID}";
            local password = "@{CM_TEST_PWD}";

            // pass test when CM reconnected
            _cm.onConnect(function() {
                resolve();
            }.bindenv(this));
            assertTrue(((ssid != "null") && (ssid != "")),  "The test requires the environment variables " + 
                "CM_TEST_SSID and CM_TEST_PWD set to the correct existing SSID and password. " +
                "You can also configure them in the .imptest-builder configuration file.");

            // delete ssid and password
            imp.clearconfiguration(CONFIG_WIFI);
            _cm.disconnect(true, 5);

            // allow for some time to make sure we are not hanging on trying to reconnect with a clean config
            // (there was a bug in the impOS which lead to this)
            imp.wakeup(10, function () {
                assertTrue(!_cm.isConnected(), "CM should NOT report connected state!");

                // reset WiFi settings, now CM should reconnect 
                imp.setwificonfiguration(ssid, password);
            }.bindenv(this));
        }.bindenv(this))
        .then(_commonThenStep.bindenv(this))
        .fail(_commonFailStep.bindenv(this));
    }

    function tearDown() {
        return "Test finished";
    }
}
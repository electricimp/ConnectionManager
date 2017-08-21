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

class ConnectionManagerSignatureTest extends ImpTestCase {

	cm = null; 
  BLINK_VALUES = [ConnectionManager.BLINK_ON_DISCONNECT ConnectionManager.BLINK_ON_CONNECT ConnectionManager.BLINK_ALWAYS ConnectionManager.BLINK_NEVER];
  START_BEHAVIOR_VALUES = [ConnectionManager.START_CONNECTED ConnectionManager.START_NO_ACTION ConnectionManager.START_DISCONNECTED];

  function _commonNegativeTest(cb) {
    local errorWasThrown = false;
    try {
      cb();
    } catch(exception) {
      errorWasThrown = true;
      this.info("Catched expected exception: " + exception);
    }
    this.assertTrue(errorWasThrown, "Expected error was not thrown!");
  }

  function _singleConstructorTest(blink, start, stayConnectedd, retryOnTimeout) {
    cm = ConnectionManager({
      "startupBehavior": start,
      "stayConnected": stayConnectedd,
      "retryOnTimeout": retryOnTimeout,
      "connectTimeout": 90,
      "ackTimeout": 3,
      "checkTimeout": 10,
      "blinkupBehavior": blink
    });

    this.info("testing constructor (blink=" + start + ", start=" + blink + ", stayConnectedd=" + stayConnectedd + ", retryOnTimeout=" + retryOnTimeout + "): cm is " + cm);
  }

  function setUp() {
    return "No setUp needed for this test";
  }

  //Checking that neither of valid arg combinations will result in error
  function testConstructor() {
    foreach (start in START_BEHAVIOR_VALUES ) {
      foreach (blink in BLINK_VALUES ) {
        foreach (stayConnectedd in [true false]){
          foreach (retryOnTimeout in [true false]){
          _singleConstructorTest(blink, start, stayConnectedd, retryOnTimeout);
          }
        }
      }
    }
  }

  function testSetBlinkUpBehavior() {
    cm = ConnectionManager({});
    foreach (blink in BLINK_VALUES ) {
      cm.setBlinkUpBehavior(blink);
    }
    // _commonNegativeTest(function() {
    //     cm.setBlinkUpBehavior(100);
    //   }.bindenv(this));
    // _commonNegativeTest(function() {
    //     cm.setBlinkUpBehavior(-1);
    //   }.bindenv(this));
  }

  function testOnTimeout() {
    cm = ConnectionManager({});
    cm.onTimeout(function() {
       server.sleepfor(600);
    });
    cm.onTimeout(null);
    cm.onTimeout(function() {
       server.sleepfor(60);
    });
  }

  function tearDown() {
    return "Test finished";
  }
}

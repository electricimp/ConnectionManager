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

class ConnectDisconnectTest extends ImpTestCase {

  cm = null;

  function setUp() {
    this.info("running setUp");
    cm = ConnectionManager();
  }

  /*
  * disconnects and connects device using CM
  *
  */
  function testSingleConnectDisconnectCMAsync() {
    return Promise(function(resolve, reject) {
      cm.onDisconnect(function(expected) {
        assertTrue(!server.isconnected(), "should NOT be connected!");
        assertTrue(!cm.isConnected(), "CM should NOT report connected state!");
        cm.connect();
      }.bindenv(this));

      cm.onConnect(function() {
        resolve();
      }.bindenv(this));

      cm.disconnect();
      assertTrue(!server.isconnected(), "should NOT be connected!");
      assertTrue(!cm.isConnected(), "CM should NOT report connected state!");
    }.bindenv(this))
    .then(function(val) {
        assertTrue(cm.isConnected(), "CM should report state as connected!");
        assertTrue(server.isconnected(), "should be connected again!");
        _resetCM.call(this);
    }.bindenv(this))
    .fail(function(valueOrReason) {
        _resetCM.call(this);
        throw valueOrReason;
      }.bindenv(this));
  }

  /*
  * Verifies that more than one disconnect() invocation doesn't result in incorect behavior
  *
  */
  function testDoubleDisconnectAsync() {
    assertTrue(server.isconnected(), "Failed pre-run saanity check");
    return Promise(function(resolve, reject) {
      cm.onDisconnect(function(expected) {
        assertTrue(!server.isconnected(), "should NOT be connected!");
        assertTrue(!cm.isConnected(), "CM should NOT report connected state!");
        cm.connect();
      }.bindenv(this));

      cm.disconnect();
      assertTrue(!server.isconnected(), "should NOT be connected!");
      assertTrue(!cm.isConnected(), "CM should NOT report connected state!");

      cm.onConnect(function() {
        resolve();
      }.bindenv(this));

      cm.disconnect();
      assertTrue(!server.isconnected(), "should NOT be connected!");
      assertTrue(!cm.isConnected(), "CM should NOT report connected state!");
    }.bindenv(this))
    .then(function(val) {
        assertTrue(cm.isConnected(), "CM should report state as connected!");
        assertTrue(server.isconnected(), "should be connected again!");
        _resetCM.call(this);
    }.bindenv(this))
    .fail(function(valueOrReason) {
        _resetCM.call(this);
        throw valueOrReason;
      }.bindenv(this));
  }

/*
* Verifies that more than one connect() invocation doesn't lead to disconnection
*
*/
  function testDoubleConnectAsync() {
    assertTrue(server.isconnected(), "Failed pre-run saanity check");
    return Promise(function(resolve, reject) {
      cm.connect();
      assertTrue(server.isconnected(), "should be connected!");
      assertTrue(cm.isConnected(), "CM should report connected state!");

      cm.onConnect(function() {
        assertTrue(server.isconnected(), "should be connected!");
        assertTrue(cm.isConnected(), "CM should report connected state!");
        resolve();
      }.bindenv(this));

      cm.connect();
      assertTrue(server.isconnected(), "should be connected!");
      assertTrue(cm.isConnected(), "CM should report connected state!");
    }.bindenv(this))
    .then(function(val) {
        assertTrue(cm.isConnected(), "CM should report state as connected!");
        assertTrue(server.isconnected(), "should be connected again!");
        _resetCM.call(this);
    }.bindenv(this))
    .fail(function(valueOrReason) {
        _resetCM.call(this);
        throw valueOrReason;
      }.bindenv(this));
  }

  function _checkConnectForCommon(needDisconnect = false) {
    local flag = 0;
    assertTrue(server.isconnected(), "Failed pre-run saanity check");
    if (needDisconnect) {
      cm.disconnect();
      assertTrue(!server.isconnected(), "should NOT be connected!");
    }
    return Promise(function(resolve, reject) {
      cm.onDisconnect(function(expected) {
        assertTrue(!cm.isConnected(), "should NOT be connected!");
        assertTrue(!server.isconnected(), "should NOT be connected!");

        cm.onConnect(function() {
          assertTrue(flag==2, "flag should be 2 now");
          flag++;
          resolve();
        }.bindenv(this));
        flag++;
        cm.connect();
      }.bindenv(this));

      cm.connectFor(function() {
        assertTrue(server.isconnected(), "inside connectFor: should be connected!");
        flag++;
      }.bindenv(this));
    }.bindenv(this))
    .then(function(val) {
        assertTrue(cm.isConnected(), "CM should report state as connected!");
        assertTrue(server.isconnected(), "should be connected again!");
        assertTrue(flag==3, "flag should be 3 now");
        _resetCM.call(this);
    }.bindenv(this))
    .fail(function(valueOrReason) {
        _resetCM.call(this);
        throw valueOrReason;
      }.bindenv(this));
  }

  /*
  * sets connectFor callback calls cm.disconnect before
  *
  */
  function testConnectForFromDisconnectedStateAsync() {
    return _checkConnectForCommon(true);
  }

  /*
  * sets connectFor callback without calling cm.disconnect before
  *
  */
  function testConnectForAsync() {
    return _checkConnectForCommon(false);
  }

  function tearDown() {
    _resetCM.call(this);
    return "Test finished";
  }

  /*
  * resets Cm state to default ones
  *
  */
  function _resetCM() {
    info("reseting CM");
    //setting behavior constants to default
    cm.setBlinkUpBehavior(ConnectionManager.BLINK_ON_DISCONNECT);

    //resetting callbacks for events
    cm.onConnect(null);
    cm.onTimeout(null);
    cm.onDisconnect(null);

    cm.connect();
  }

}
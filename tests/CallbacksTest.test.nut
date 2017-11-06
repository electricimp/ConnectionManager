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

class CallbacksTest extends ImpTestCase {

  cm = null;

  function setUp() {
    this.info("running setUp");
    cm = ConnectionManager();
  }

  /*
  * sets onDisconnect callback and disconnects device using CM
  *
  */
  function testOnDisconnectAsync() {
    return Promise(function(resolve, reject) {
      cm.onDisconnect(function(expected) {
        cm.connect();
      }.bindenv(this));

      cm.onConnect(function() {
        resolve();
      }.bindenv(this));

      cm.disconnect();
      assertTrue(!server.isconnected(), "should NOT be connected!");
    }.bindenv(this))
    .then(function(val) {
        info("should be online now");
        assertTrue(server.isconnected(), "should be connected again!");
        _resetCM.call(this);
    }.bindenv(this))
    .fail(function(valueOrReason) {
        _resetCM.call(this);
        throw valueOrReason;
      }.bindenv(this));
  }

 /*
  * sets onConnect callback and disconnects device using CM
  *
  */
  function testOnConnectAsync() {
    local flag = 0;
    return Promise(function(resolve, reject) {
      cm.onDisconnect(function(expected) {
        assertTrue(!flag, "should be 0 now");
        cm.connect();
      }.bindenv(this));

      cm.onConnect(function() {
        flag++;
        info("flag = " + flag);
        resolve();
      }.bindenv(this));

      assertTrue(!flag, "should 0 before re-connect");
      cm.disconnect();
      assertTrue(!server.isconnected(), "should NOT be connected!");
    }.bindenv(this))
    .then(function(val) {
      //not assertTrue(flag, ...) to ensure flag was increased exactly one time
      assertTrue(flag==1, "connected again, should be 1 now");
      _resetCM.call(this);
    }.bindenv(this))
    .fail(function(valueOrReason) {
      _resetCM.call(this);
      throw valueOrReason;
    }.bindenv(this));
  }

 /*
  * sets onNextConnect callback and disconnects device using CM
  *
  */
  function testOnNextConnectAsync() {
    local flag = 0;
    return Promise(function(resolve, reject) {
      cm.onDisconnect(function(expected) {
        assertTrue(!flag, "should be 0 now");
        cm.onNextConnect(function() {
          flag++;
          info("flag = " + flag);
          resolve();
        }.bindenv(this));
        cm.connect();
      }.bindenv(this));

      assertTrue(!flag, "should be 0 before next connect");
      cm.disconnect();

      assertTrue(!server.isconnected(), "should NOT be connected!");
    }.bindenv(this))
    .then(function(val) {
        //not assertTrue(flag, ...) to ensure flag was increased exactly one time
        assertTrue(flag==1, "should be 1 now");
        _resetCM.call(this);
    }.bindenv(this))
    .fail(function(valueOrReason) {
        _resetCM.call(this);
        throw valueOrReason;
      }.bindenv(this));
  }

 /*
  * removes onConnect callback checks it is not firing any more
  *
  */
  function testOnConnectRemovalAsync() {
    local flag = 0;
    return Promise(function(resolve, reject) {
      cm.onConnect(function() {
        flag++;
        info("flag = " + flag);
        //in case onConnect will be called twice, second time flag will become 2 and test fails
        assertTrue(flag==1, "should be 1 now");
        resolve();
      }.bindenv(this));

      //cm.connect returns false iff it's already in process of connection
      assertTrue(cm.connect(), "should NOT be connecting now");
    }.bindenv(this))
    .then(function(val) {
      //not assertTrue(flag, ...) to ensure flag was increased exactly one time
      cm.onConnect(null);
      cm.connect();
      _resetCM.call(this);
    }.bindenv(this))
    .fail(function(valueOrReason) {
      _resetCM.call(this);
      throw valueOrReason;
    }.bindenv(this));
  }

  function tearDown() {
    this.cm.connect();
    return "Test finished";
  }

  function _resetCM(e = null) {
    this.info("reseting CM");
    //setting behavior constants to default
    this.cm.setBlinkUpBehavior(ConnectionManager.BLINK_ON_DISCONNECT);

    //resetting callbacks for events
    this.cm.onConnect(null);
    this.cm.onTimeout(null);
    this.cm.onDisconnect(null);

    this.cm.connect();
  }

}
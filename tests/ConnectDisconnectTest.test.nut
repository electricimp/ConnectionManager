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
    flag = false;

  /*
  * disconnects and connects device using CM
  *
  */
    function testSingleConnectDisconnectCMAsync() {
    cm = ConnectionManager({"stayConnected" : true});
    this.assertTrue(server.isconnected(), "should be connected!");
    this.assertTrue(this.cm.isConnected(), "CM should report state as connected!");
    this.info("going to disconnect");
    this.cm.disconnect();
    this.assertTrue(!server.isconnected(), "should NOT be connected!");
    this.assertTrue(!cm.isConnected(), "CM should NOT report connected state!");
    return Promise(function (resolve, reject) {
      imp.wakeup(3, function() {
        this.cm.connect();
      }.bindenv(this));
      imp.wakeup(10, function () {
          try {
            this.info("should be online now");
            this.assertTrue(server.isconnected(), "should be connected again!");
            this.assertTrue(this.cm.isConnected(), "CM should report state as connected!");
            resolve();
          } catch (e) {
            reject(e);
          }
      }.bindenv(this));
    }.bindenv(this));
  }

/*
*Verifies that more than one disconnect() invocation doesn't result in incorect behavior
*
*/
function testDoubleDisconnectAsync() {
 cm = ConnectionManager();
    if (!cm.isConnected()) {
     cm.connect();
     this.info("Was disconnected, should be connected now.");
    }
    this.assertTrue(server.isconnected(), "Expected to be connected aftter ConnectionManager.connect() invocation");
    this.cm.disconnect();
    this.assertTrue(!server.isconnected(), "should NOT be connected!");
     return Promise(function (resolve, reject) {
      imp.wakeup(5, function() {
        this.assertTrue(!server.isconnected(), "1: should NOT be connected!");
        this.cm.disconnect();
        this.assertTrue(!server.isconnected(), "2: should NOT be connected!");
        this.cm.connect();
      }.bindenv(this));
      imp.wakeup(10, function () {
          try {
            this.assertTrue(server.isconnected(), "should be connected again!");
            resolve();
          } catch (e) {
            reject(e);
          }
      }.bindenv(this));
    }.bindenv(this));
}

/*
*Verifies that more than one connect() invocation doesn't lead to disconnection
*
*/
function testDoubleConnectAsync() {
    cm = ConnectionManager();
    if (!cm.isConnected()) {
     cm.connect();
     this.info("Was disconnected, should be connected now.");
    }
    
    this.assertTrue(server.isconnected(), "Expected to be connected aftter ConnectionManager.connect() invocation");
     return Promise(function (resolve, reject) {
      imp.wakeup(3, function() {
        this.cm.connect();
        this.assertTrue(server.isconnected(), "should be connected again!");
        this.cm.connect();
      }.bindenv(this));
      imp.wakeup(10, function () {
          try {
            this.info("should be online now");
            this.assertTrue(server.isconnected(), "should be connected again!");
            resolve();
          } catch (e) {
            reject(e);
          }
      }.bindenv(this));
    }.bindenv(this));
}

  function _checkConnectForCommon(needDisconnect = false) {
    cm = ConnectionManager();
    this.flag = false;
    this.assertTrue(!this.flag, "should NOT be true yet");
    this.assertTrue(server.isconnected(), "0: should be connected!");
    if (needDisconnect) {
      this.info("going to disconnect, because I can do so");
      this.cm.disconnect();
      this.assertTrue(!server.isconnected(), "1: should NOT be connected!");
    }
    return Promise(function (resolve, reject) {
      imp.wakeup(0, function() {
        this.cm.connectFor(function() {
            this.info("inside ConnectFor");
            this.flag = true;
          }.bindenv(this));
      }.bindenv(this));
      imp.wakeup(15, function() {
        this.assertTrue(!this.cm.isConnected(), "2.0: should NOT be connected!");
        this.assertTrue(!server.isconnected(), "2.1: should NOT be connected!");
        this.cm.connect();
        this.info("I'm here!!!11one");
      }.bindenv(this));
      imp.wakeup(20, function () {
          try {
            this.info("should be online now");
            this.assertTrue(server.isconnected(), "3: should be connected again!");
            this.assertTrue(this.flag, "should be true now");
            resolve();
          } catch (e) {
            reject(e);
          }
      }.bindenv(this));
    }.bindenv(this));
  }


 /*
  * sets connectFor callback calls cm.disconnect before
  *
  */
 function testConnectForFromDisconnectedStateAsync() {
   local f = function() {return _checkConnectForCommon(true);}.bindenv(this);
  return f();
 }

/*
  * sets connectFor callback without calling cm.disconnect before
  *
  */
function testConnectForAsync() {
  local f = function() {return _checkConnectForCommon(false);}.bindenv(this);
  return f();
}

function tearDown() {
  this.cm = ConnectionManager({"stayConnected" : true});
  this.cm.connect();
  return "Test finished";
}

}

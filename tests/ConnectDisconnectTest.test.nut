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
  static TIMEOUT_1 = 5;
  static TIMEOUT_2 = 10;
  static TIMEOUT_3 = 15;
  static TIMEOUT_4 = 20;

  function setUp() {
    this.info("running setUp");
    cm = ConnectionManager();
  }

  /*
  * disconnects and connects device using CM
  *
  */
  function testSingleConnectDisconnectCMAsync() {
    this.assertTrue(server.isconnected(), "should be connected!");
    this.assertTrue(this.cm.isConnected(), "CM should report state as connected!");
    this.info("going to disconnect");
    this.cm.disconnect();
    this.assertTrue(!server.isconnected(), "should NOT be connected!");
    this.assertTrue(!cm.isConnected(), "CM should NOT report connected state!");
    return Promise(function (resolve, reject) {
      imp.wakeup(this.TIMEOUT_1, function() {
        this.cm.connect();
      }.bindenv(this));
      imp.wakeup(this.TIMEOUT_2, function () {
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
  * Verifies that more than one disconnect() invocation doesn't result in incorect behavior
  *
  */
  function testDoubleDisconnectAsync() {
    this.assertTrue(server.isconnected(), "Expected to be connected after ConnectionManager.connect() invocation");
    this.cm.disconnect();
    this.assertTrue(!server.isconnected(), "should NOT be connected!");
    return Promise(function (resolve, reject) {
      imp.wakeup(this.TIMEOUT_2, function() {
        this.assertTrue(!server.isconnected(), "1: should NOT be connected!");
        this.cm.disconnect();
        this.assertTrue(!server.isconnected(), "2: should NOT be connected!");
        this.cm.connect();
      }.bindenv(this));
      imp.wakeup(this.TIMEOUT_4, function () {
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
* Verifies that more than one connect() invocation doesn't lead to disconnection
*
*/
  function testDoubleConnectAsync() {
    if (!cm.isConnected()) {
     cm.connect();
     this.info("Was disconnected, should be connected now.");
    }
    return Promise(function (resolve, reject) {
      imp.wakeup(this.TIMEOUT_1, function() {
        this.cm.connect();
        this.assertTrue(server.isconnected(), "should be connected again!");
        this.cm.connect();
      }.bindenv(this));
      imp.wakeup(this.TIMEOUT_2, function () {
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
    local flag = false;
    this.assertTrue(server.isconnected(), "0: should be connected!");
    if (needDisconnect) {
      this.cm.disconnect();
      this.assertTrue(!server.isconnected(), "1: should NOT be connected!");
    }
    return Promise(function (resolve, reject) {
      imp.wakeup(0, function() {
        this.cm.connectFor(function() {
            this.info("inside ConnectFor");
            this.assertTrue(server.isconnected(), "inside connectFor: should be connected!");
            flag = true;
          }.bindenv(this));
      }.bindenv(this));
      imp.wakeup(this.TIMEOUT_3, function() {
        this.assertTrue(!this.cm.isConnected(), "2.0: should NOT be connected!");
        this.assertTrue(!server.isconnected(), "2.1: should NOT be connected!");
        this.cm.connect();
      }.bindenv(this));
      imp.wakeup(this.TIMEOUT_4, function () {
          try {
            this.info("should be online now");
            this.assertTrue(server.isconnected(), "3: should be connected again!");
            this.assertTrue(flag, "should be true now");
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
    this.cm.connect();
    return "Test finished";
  }

}
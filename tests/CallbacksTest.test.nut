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
    flag = false;


  /*
  * sets onDisconnect callback and disconnects device using CM
  *
  */
  function testOnDisconnectAsync() {
    cm = ConnectionManager({"stayConnected" : true});
    cm.onDisconnect(function(expected) {
      this.cm.connect();
    }.bindenv(this));
    this.assertTrue(server.isconnected(), "should be connected!");
    this.info("going to disconnect");
    this.cm.disconnect();
    this.assertTrue(!server.isconnected(), "should NOT be connected!");
    return Promise(function (resolve, reject) {
      imp.wakeup(10, function () {
          try {
            this.info("should be online now");
            this.assertTrue(server.isconnected(), "should be connected again!");
            resolve();
          } catch (e) {
            this.cm.connect(); 
            reject(e);
          }
      }.bindenv(this));
    }.bindenv(this));
  }

 /*
  * sets onConnect callback and disconnects device using CM
  *
  */
  function testOnConnectAsync() {
    cm = ConnectionManager({"stayConnected" : true});
    this.flag = false;
    cm.onConnect(function() {
      this.flag = true;
    }.bindenv(this));
    this.assertTrue(!this.flag, "should NOT be true yet");
    this.assertTrue(server.isconnected(), "should be connected!");
    this.info("going to disconnect");
    this.cm.disconnect();
    this.assertTrue(!server.isconnected(), "should NOT be connected!");
    return Promise(function (resolve, reject) {
      imp.wakeup(3, function() {
        this.cm.connect();
      }.bindenv(this));
      imp.wakeup(10, function () {
          try {
            this.info("should be online now");
            this.assertTrue(server.isconnected(), "should be connected again!");
            this.assertTrue(this.flag, "should be true now");
            resolve();
          } catch (e) {
            reject(e);
          }
      }.bindenv(this));
    }.bindenv(this));
  }

 /*
  * sets onNextConnect callback and disconnects device using CM
  *
  */
  function testOnNextConnectAsync() {
    cm = ConnectionManager();
    this.flag = false;
    cm.onNextConnect(function() {
      this.flag = true;
    }.bindenv(this));
    this.assertTrue(!this.flag, "should NOT be true yet");
    this.assertTrue(server.isconnected(), "should be connected!");
    this.info("going to disconnect");
    this.cm.disconnect();
    this.assertTrue(!server.isconnected(), "should NOT be connected!");
    return Promise(function (resolve, reject) {
      imp.wakeup(3, function() {
        this.cm.connect();
      }.bindenv(this));
      imp.wakeup(10, function () {
          try {
            this.info("should be online now");
            this.assertTrue(server.isconnected(), "should be connected again!");
            this.assertTrue(this.flag, "should be true now");
            resolve();
          } catch (e) {
            reject(e);
          }
      }.bindenv(this));
    }.bindenv(this));
  }

 /*
  * removes onConnect callback checks it is not firing any more
  *
  */
  function testOnConnectRemovalAsync() {
    cm = ConnectionManager({"checkTimeout": 0.1 });
    this.flag = false;
    cm.onConnect(function() {
      this.flag = true;
    }.bindenv(this));
    //cm.connect returns false iff it's already in process of connection
    this.assertTrue(cm.connect(), "should NOT be connecting now");
    return Promise(function (resolve, reject) {
      imp.wakeup(3, function() {
        this.assertTrue(this.flag, "flag should be true here");
        this.flag = false;
        //now nothing should be called on connnect
        this.cm.onConnect(null);
        this.cm.connect();
      }.bindenv(this));
      imp.wakeup(10, function () {
          try {
            this.assertTrue(!this.flag, "flag should NOT be true");
            resolve();
          } catch (e) {
            reject(e);
          }
      }.bindenv(this));
    }.bindenv(this));
  }


  function tearDown() {
    this.cm = ConnectionManager({"stayConnected" : true});
    this.cm.connect();
    return "Test finished";
  }

}

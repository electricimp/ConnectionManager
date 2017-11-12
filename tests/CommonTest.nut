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

class CommonTest extends ImpTestCase {

    _cm = null;

    function _setUp() {
        info("running setUp");
        _cm = ConnectionManager();
    }

    function _resetCM() {
        info("reseting CM");
        //setting behavior constants to default
        _cm.setBlinkUpBehavior(ConnectionManager.BLINK_ON_DISCONNECT);

        //resetting callbacks for events
        _cm.onConnect(null);
        _cm.onTimeout(null);
        _cm.onDisconnect(null);

        _cm.connect();
    }

    /*
    *function that is used as a common fail handler in all Promise.fail invocations
    *
    */
    function _commonFailStep(valueOrReason = null) {
        _resetCM();
        throw valueOrReason;
    }

}
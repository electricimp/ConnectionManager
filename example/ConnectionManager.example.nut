// MIT License

// Copyright 2015-2018 Electric Imp

// SPDX-License-Identifier: MIT

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.


#require "ConnectionManager.lib.nut:3.1.1"

// Instantiate ConnectionManager so BlinkUp is always enabled,
// and starts connected.
cm <- ConnectionManager({
    "startupBehavior": CM_START_CONNECTED,
    "connectTimeout": 90,
    "blinkupBehavior": CM_BLINK_ALWAYS
});

// Set the timeout behaviour after failing to connect for 90 seconds.
cm.onTimeout(function() {
     // Go to sleep for 10 minutes
     server.sleepfor(600);
 });

// Set the recommended buffer size
imp.setsendbuffersize(8096);

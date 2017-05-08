#require "ConnectionManager.class.nut:1.1.0"

// Instantiate ConnectionManager so BlinkUp is always enabled,
// and starts connected.
cm <- ConnectionManager({
    "startConnected": true,
    "connectTimeout": 90,
    "blinkupBehavior": ConnectionManager.BLINK_ALWAYS
});

// Set the timeout behaviour after failing to connect for 90 seconds.
cm.onTimeout(function() {
     // Go to sleep for 10 minutes 
     server.sleepfor(600);
 });

// Set the recommended buffer size 
imp.setsendbuffersize(8096);
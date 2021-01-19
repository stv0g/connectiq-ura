using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Communications;
using Toybox.Timer;

class DepartureView extends WatchUi.View {
	var departures = null;
	var tmr;
	var app;
    
    function initialize(a) {
    	WatchUi.View.initialize();
    	
    	app = a;
    	
    	updateDepartures();
    }

    function onLayout(dc) {

    }

    function onShow() {
    	tmr = new Timer.Timer();
    	tmr.start(method(:updateDepartures), 10000, true);
    }
    

    function onHide() {
    	tmr.stop();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var mid = dc.getWidth() / 2;
        var top = Graphics.getFontAscent(Graphics.FONT_SMALL);

        if (departures != null) {
        	if (departures.size() > 0) {
	        	for (var i = app.offset; i < departures.size(); i++) {
	        		var dep = departures[i];
	        		        		
	        		dc.drawText(mid, top, Graphics.FONT_SMALL, dep["line"] + " " + dep["dest"], Graphics.TEXT_JUSTIFY_CENTER);
	        		top += Graphics.getFontAscent(Graphics.FONT_TINY);
	        		dc.drawText(mid, top, Graphics.FONT_XTINY, dep["delta_str"], Graphics.TEXT_JUSTIFY_CENTER);
	        		
	        		top += Graphics.getFontHeight(Graphics.FONT_SMALL);     
	        	} 
	        }
	        else {
	            dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2), Graphics.FONT_SMALL, "No departures!", Graphics.TEXT_JUSTIFY_CENTER );
	        }
	    }
        else {
            dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2), Graphics.FONT_SMALL, "Loading...", Graphics.TEXT_JUSTIFY_CENTER );
        }
    }
    
    function updateDepartures() {
    	var parameters = {
    		"id"  => app.stopId,
    		"limit" => 10
    	};
    	var options = {
    		:method => Communications.HTTP_REQUEST_METHOD_GET,
    		:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
    	};
    	
    	Communications.makeWebRequest(app.api_url + "/departures", parameters, options, method(:requestCompleted));
    }
    
    function requestCompleted(responseCode, data) {
    	System.println("Request completed: " + responseCode);
    
    	if (responseCode == 200) {
    		departures = data;
    		WatchUi.requestUpdate();
    	}
    }
}

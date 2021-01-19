using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;

class CompassDrawable extends WatchUi.Drawable {

	var bearing = 0;
	var aWidth = 2;
	var aLength = 6;
	var aColor = Graphics.COLOR_RED;
	
	function initialize(settings) {
		WatchUi.Drawable.initialize(settings);
		
		aWidth  = settings[:aWidth];
		aLength = settings[:aLength];
		aColor  = settings[:aColor];
	}

	function setBearing(b) {
		bearing = Math.PI * (b - 90) / 180;
	}

	function draw(dc) {
		var rPts = new[7];
		var aPts = [
			[-0.5*aLength, -0.5*aWidth],
			[ 0.0,         -0.5*aWidth],
			[ 0.0,         -1.0*aWidth],
			[ 0.5*aLength,           0],
			[ 0.0,          1.0*aWidth],
			[ 0.0,          0.5*aWidth],
			[-0.5*aLength,  0.5*aWidth]
		];
	
		var s = Math.sin(bearing);
  		var c = Math.cos(bearing);

		for (var i = 0; i < 7; i++) {
			var p = aPts[i];
			rPts[i] = [
				locX + width  * (p[0] * c - p[1] * s),
				locY + height * (p[0] * s + p[1] * c)
			];
		}

		dc.setColor(aColor, Graphics.COLOR_TRANSPARENT);
		dc.fillPolygon(rPts);
	}
}


class BusStopView extends WatchUi.View {
	var stops = null;
	var app;
	var compass;
	
	var offset = 0;
	var sensors;
	var position;
    
    function initialize(a) {
    	WatchUi.View.initialize();
    	
    	app = a;
    }

    function onLayout(dc) {
    	var compassX = dc.getWidth() / 2;
    	var compassY = dc.getHeight() / 2 - 60;
    	
    	compass = new CompassDrawable({
    		:locX => compassX,
    		:locY => compassY,
    		:width => 11,
    		:height => 11,
    		:aWidth => 2,
    		:aLength => 6,
    		:aColor => Graphics.COLOR_DK_RED
    	});
    }

    function onShow() {
    	Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        
	    Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
    	Sensor.enableSensorEvents(method(:onSensor));
    }
    
    function onHide() {
    	Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:updateStops));
    }
    
    function onPosition(positionInfo) {
    	System.println("Position: " + positionInfo.position.toDegrees());
    
    	position = positionInfo;
    	updateStops();
    }

	function onSensor(sensorInfo) {
	    System.println("Heading: " + 180.0 * Math.PI / sensorInfo.heading);
	    
	    sensors = sensorInfo;
		requestUpdate();
	}

    function onUpdate(dc) {
        // Set background color
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        
        var midW = dc.getWidth() / 2;
        var midH = dc.getHeight() / 2;
        var top = Graphics.getFontAscent(Graphics.FONT_SMALL);
        
        if (stops != null) {
        	if (stops.size() > 0) {
		        if (offset >= stops.size()) {
		        	offset = stops.size() - 1;
		        }
		        
		        var stop = stops[offset];
		        
		        var dist = stop["dist"] < 1000
		        	       ? stop["dist"].format("%.0f") + " m"
		        	       : (stop["dist"] / 1000).format("%.1f") + " km";
		        	       
				var bearing = stop["bearing"].format("%.0f") + "° (" + stop["bearing_str"] + ")";
		        	       
				var y = midH;
				
				var bDeg = stop["bearing"];
				var hDeg = 180.0 * sensors.heading / Math.PI;
	
				dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
				dc.setPenWidth(4);
				dc.drawArc(midW, midH, midW-2, Graphics.ARC_CLOCKWISE, -bDeg+5+90, -bDeg-5+90);
				
				dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
				dc.setPenWidth(4);
				dc.drawArc(midW, midH, midW-2, Graphics.ARC_CLOCKWISE, -hDeg+5, -hDeg-5);
		        
		        compass.setBearing(bDeg);
		        compass.draw(dc);
				
				dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		        dc.drawText(midW, y, Graphics.FONT_MEDIUM, stop["name"], Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
		        
		        y += dc.getFontAscent(Graphics.FONT_SMALL) + dc.getFontDescent(Graphics.FONT_MEDIUM);
		        
		        if (stop["indicator"].length() > 0) {
		        	dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		        	dc.drawText(midW, y, Graphics.FONT_SMALL, stop["indicator"], Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
		        }
		        
		        y += dc.getFontAscent(Graphics.FONT_TINY) + dc.getFontDescent(Graphics.FONT_SMALL);
		        
		        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		        dc.drawText(midW, y, Graphics.FONT_TINY, dist, Graphics.TEXT_JUSTIFY_CENTER);
		        
		        y += dc.getFontAscent(Graphics.FONT_TINY) + dc.getFontDescent(Graphics.FONT_TINY);
		        
		        dc.drawText(midW, y, Graphics.FONT_TINY, bearing, Graphics.TEXT_JUSTIFY_CENTER);
		        
		        app.stopId = stop["id"];
	        }
	        else {
	            dc.drawText(midW, midH, Graphics.FONT_SMALL, "No stops found!", Graphics.TEXT_JUSTIFY_CENTER);
	        }
	    }
        else {
            dc.drawText(midW, midH, Graphics.FONT_SMALL, "Loading...", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
    
    function updateStops() {
    	var degs = position.position.toDegrees();
    	var params = {
    		"latitude"  => degs[0],
    		"longitude" => degs[1],
    		"distance" => 10000,
    		"limit" => 50
    	};

    	var options = {
    		:method => Communications.HTTP_REQUEST_METHOD_GET,
    		:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
    	};

    	Communications.makeWebRequest(app.api_url + "/stops", params, options, method(:requestCompleted));
    }
    
    function requestCompleted(responseCode, data) {
    	System.println("Request completed: " + responseCode);
    
    	if (responseCode == 200) {
    		stops = data;
    		WatchUi.requestUpdate();
    	}
    }
}

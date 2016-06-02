using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Communications as Comm;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Timer as Timer;

class BusStopView extends Ui.View {
	var schedule = null;
	var tmr;
    
    function intialize() {
    	View.initialize();
    }

    //! Load your resources here
    function onLayout(dc) {
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    	tmr = new Timer.Timer();
    	tmr.start(method(:redraw), 1000, true);
    }
    
    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    	tmr.stop();
    }

    //! Update the view
    function onUpdate(dc) {
    	var string;

        // Set background color
        dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK );
        dc.clear();
        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );

        if( schedule != null ) {
        	var ts = new Time.Moment(schedule[1][4] / 1000);
        	var duration = Time.now().subtract(ts);
        	var ts_greg = Time.Gregorian.info(ts, Time.FORMAT_MEDIUM);
        	var dur_greg =  Time.Gregorian.info(new Time.Moment(duration.value()), Time.FORMAT_SHORT);
        	
        	/* Timezone offset */
        	dur_greg.hour -= 2;
        	
        	var arr = Lang.format("$1$:$2$:$3$", [
        		(ts_greg.hour - 2),
        		(ts_greg.min).format("%02u"),
        		(ts_greg.sec).format("%02u")
        	]);
        	
        	var due = "";
        	if (dur_greg.hour > 0) {
        		due += dur_greg.hour + " h ";
        	}
        	if (dur_greg.min > 0) {
        		due += dur_greg.min + " min ";
        	}
        	if (dur_greg.sec > 0) {
        		due += dur_greg.sec + " sec ";
        	}
        	
			dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2) - 80, Gfx.FONT_LARGE, schedule[1][2], Gfx.TEXT_JUSTIFY_CENTER );        
            dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2) - 40, Gfx.FONT_SMALL, schedule[1][1], Gfx.TEXT_JUSTIFY_CENTER );
            dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2) - 20, Gfx.FONT_SMALL, schedule[1][3], Gfx.TEXT_JUSTIFY_CENTER );
            dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2) + 10, Gfx.FONT_SMALL, arr, Gfx.TEXT_JUSTIFY_CENTER );
            dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2) + 40, Gfx.FONT_SMALL, due, Gfx.TEXT_JUSTIFY_CENTER );
        }
        else {
            dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2), Gfx.FONT_SMALL, "No schedule avail", Gfx.TEXT_JUSTIFY_CENTER );
        }
    }
    
    function setPosition(info) {    	
    	var url = "http://web.0l.de:8080/";
    	var parameters = { "Circle" => info.position.toDegrees()[0] + "," + 
    							       info.position.toDegrees()[1] + ",150",
    					   "ReturnList" => "StopPointName,DestinationName,LineName,EstimatedTime" };
    	var options = { :method => Comm.HTTP_REQUEST_METHOD_GET };
    	
    	Comm.makeJsonRequest(url, parameters, options, method(:requestCompleted));
    }
    
    function requestCompleted(responseCode, data) {
    	Sys.println("Request completed: " + responseCode);
    
    	if (responseCode == 200) {
    		schedule = data;
    		redraw();
    	}
    }
    
   	function redraw() {
   		WatchUi.requestUpdate();
   	}
}

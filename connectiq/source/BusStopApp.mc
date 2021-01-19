using Toybox.Application;
using Toybox.Position;
using Toybox.Time;
using Toybox.Sensor;
using Toybox.System;

class BusStopApp extends Application.AppBase {
    var view;
    var delegate;
    var position;
    var sensors;
    var api_url;
    
    var offset = 0;
	var stopId = 0;
    
    function initialize() {
    	Application.AppBase.initialize();
    	
    	loadSettings();
    }
    
    function onSettingsChanged() {
    	loadSettings();
    }
    
    function loadSettings() {
    	var api_url_index = 1; //getProperty("api_url_index");
    	
    	switch (api_url_index) {
    		case 0:
    			api_url = "https://localhost:8080";
    			break;
    			
    		case 1:
    			api_url = "https://connectiq-ura.0l.de";
    			break;
    	}
    	
    	System.println(api_url);
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        view = new BusStopView(self);
        delegate = new BusStopDelegate(self);
        
        return [ view, delegate ];
    }

}
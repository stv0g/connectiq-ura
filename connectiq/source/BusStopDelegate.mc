using Toybox.WatchUi;

class BusStopDelegate extends WatchUi.BehaviorDelegate {
	var app;

	function initialize(a) {
		WatchUi.BehaviorDelegate.initialize();
		
		app = a;
	}
	
	function onNextPage() {
		app.view.offset += 1;
		
		WatchUi.requestUpdate();
		
		return true;
	}
	
	function onPreviousPage() {
		if (app.view.offset > 0) {
        	app.view.offset -= 1;
        	
        	WatchUi.requestUpdate();
		}
		
		return true;
	}

	function onSelect() {
		app.offset = 0;
		WatchUi.pushView(new DepartureView(app), new DepartureDelegate(app), WatchUi.SLIDE_LEFT);
		
		return true;
	}
}
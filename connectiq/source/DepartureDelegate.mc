using Toybox.WatchUi;

class DepartureDelegate extends WatchUi.BehaviorDelegate {
	var app;

	function initialize(a) {
		WatchUi.BehaviorDelegate.initialize();
		
		app = a;
	}
	
	function onNextPage() {
		app.offset += 1;
		
		WatchUi.requestUpdate();
		
		return true;
	}
	
	function onPreviousPage() {
		if (app.offset > 0) {
        	app.offset -= 1;
        	
        	WatchUi.requestUpdate();
		}
		
		return true;
	}

	function onBack() {
		app.offset = 0;
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
		
		return true;
	}
}
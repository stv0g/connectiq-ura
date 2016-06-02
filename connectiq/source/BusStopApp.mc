using Toybox.Application as App;
using Toybox.Position as Position;
using Toybox.Time as Time;

class BusStopApp extends App.AppBase {
    var mView;
    var mDelegate;
    
    function intialize() {
    	AppBase.initialize();
    }

    //! onStart() is called on application start up
    function onStart() {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    //! onStop() is called when your application is exiting
    function onStop() {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }
    
    function fakePosition() {
        var pos = new Position.Info();
        
        pos.accuracy = 0;
		pos.altitude = 0;
		pos.heading = 0;
		pos.speed = 0;
		pos.when = Time.now();
		pos.position = new Position.Location({
			:latitude => 50.7855,
			:longitude => 6.0541,
			:format => :degrees
		});
        
        mView.setPosition(pos);
    }

    function onPosition(info) {
        positionView.setPosition(info);
    }

    //! Return the initial view of your application here
    function getInitialView() {
        mView = new BusStopView();
        mDelegate = new BusStopDelegate();
        
        fakePosition();

        return [ mView, mDelegate ];
    }

}
API_BASE="http://ivu.aseag.de/interfaces/ura"

LOC="50.7802655,6.0752138,400"
RL="StopPointName,StopID,StopPointState,StopPointIndicator,Latitude,Longitude,VisitNumber,TripID,VehicleID,LineID,LineName,DirectionID,DestinationName,DestinationText,EstimatedTime,BaseVersion"

# curl "${API_BASE}/location?searchString=*&maxResults=10000" | jq .

curl "${API_BASE}/instant_V1?Circle=${LOC}&StopPointState=0&ReturnList=${RL}"

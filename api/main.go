package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	geo "github.com/kellydunn/golang-geo"
)

var returnList = []string{
	"StopPointName",
	"StopID",
	"StopPointIndicator",
	"StopPointState",
	"Latitude",
	"Longitude",
}

var apiBase string = "http://ivu.aseag.de/interfaces/ura"

type StopPoint struct {
	Name          string     `json:"name"`
	ID            int        `json:"id"`
	Indicator     string     `json:"indicator"`
	State         bool       `json:"state"`
	Coordinates   *geo.Point `json:"coord"`
	Distance      float64    `json:"dist"`
	Bearing       float64    `json:"bearing"`
	BearingString string     `json:"bearing_str"`
}

func BearingToCardinal(b float64) string {
	var card = []string{"N", "NE", "E", "SE", "S", "SW", "W", "NW"}

	b += 22.5
	if b < 0 {
		b += 360
	}
	b /= 45

	return card[int(b)]
}

func (sp *StopPoint) UnmarshalJSON(buf []byte) error {
	// Ex: [0,"Bahnhof Rothe Erde","100302","H.1",0,50.7703152,6.1174127]

	var rType int
	var id string
	var state int
	var err error
	var lat, lng float64

	tmp := []interface{}{&rType, &sp.Name, &id, &sp.Indicator, &state, &lat, &lng}
	wantLen := len(tmp)

	if err := json.Unmarshal(buf, &tmp); err != nil {
		return fmt.Errorf("Failed to parse: %s", buf)
	}

	sp.ID, err = strconv.Atoi(id)
	if err != nil {
		return nil
	}

	sp.State = state != 0
	sp.Coordinates = geo.NewPoint(lat, lng)

	if rType != 0 {
		return fmt.Errorf("Invalid response type: %d != 0", rType)
	}

	if g, e := len(tmp), wantLen; g != e {
		return fmt.Errorf("wrong number of fields in Notification: %d != %d", g, e)
	}

	return nil
}

type Prediction struct {
	LineName        string    `json:"line"`
	DestinationName string    `json:"dest"`
	EstimatedTime   time.Time `json:"estimated"`
	ExpireTime      time.Time `json:"expire"`
	Delta           int       `json:"delta"`
	DeltaString     string    `json:"delta_str"`
}

func (p *Prediction) UnmarshalJSON(buf []byte) error {
	// Ex: [1,"33","Vaals Heuvel",1610732635000,1610732880000]

	var rType int
	var estimated, expired json.Number

	tmp := []interface{}{&rType, &p.LineName, &p.DestinationName, &estimated, &expired}
	wantLen := len(tmp)

	if err := json.Unmarshal(buf, &tmp); err != nil {
		return fmt.Errorf("Failed to parse: %s", buf)
	}

	expiredInt, _ := expired.Int64()
	estimatedInt, _ := estimated.Int64()

	p.ExpireTime = time.Unix(expiredInt/1000, 0)
	p.EstimatedTime = time.Unix(estimatedInt/1000, 0)

	if rType != 1 {
		return fmt.Errorf("Invalid response type: %d != 1", rType)
	}

	if g, e := len(tmp), wantLen; g != e {
		return fmt.Errorf("wrong number of fields in Notification: %d != %d", g, e)
	}

	return nil
}

func main() {
	r := gin.Default()

	r.GET("/stops", func(c *gin.Context) {
		latStr := c.Query("latitude")
		lngStr := c.Query("longitude")
		distStr := c.Query("distance")
		limitStr := c.Query("limit")

		var lat, lng float64
		var dist float64
		var err error
		var limit int

		lat, err = strconv.ParseFloat(latStr, 64)
		if err != nil {

		}

		lng, err = strconv.ParseFloat(lngStr, 64)
		if err != nil {

		}

		point := geo.NewPoint(lat, lng)

		dist, err = strconv.ParseFloat(distStr, 64)
		if err != nil {

		}

		limit, err = strconv.Atoi(limitStr)
		if err != nil {

		}

		res, _ := http.Get(apiBase + "/instant_V1" +
			fmt.Sprintf("?Circle=%f,%f,%f", point.Lat(), point.Lng(), dist) +
			"&StopPointState=0" +
			"&ReturnList=" + strings.Join(returnList, ","))

		var sps = []StopPoint{}

		scanner := bufio.NewScanner(res.Body)

		if !scanner.Scan() {

		}

		_ = scanner.Bytes()

		for scanner.Scan() {
			line := scanner.Bytes()

			var sp StopPoint
			err = json.Unmarshal(line, &sp)
			if err != nil {
				continue
			}

			sp.Distance = point.GreatCircleDistance(sp.Coordinates) * 1000
			sp.Bearing = point.BearingTo(sp.Coordinates)
			sp.BearingString = BearingToCardinal(sp.Bearing)

			sps = append(sps, sp)
		}

		sort.Slice(sps, func(a, b int) bool {
			return sps[a].Distance < sps[b].Distance
		})

		if limit > len(sps) || limit == 0 {
			limit = len(sps)
		}

		c.JSON(200, sps[:limit])
	})

	r.GET("/departures", func(c *gin.Context) {
		var err error
		var limit int

		idStr := c.Query("id")
		limitStr := c.Query("limit")

		id, err := strconv.Atoi(idStr)
		if err != nil {

		}

		limit, err = strconv.Atoi(limitStr)
		if err != nil {

		}

		res, _ := http.Get(apiBase + "/instant_V1" +
			fmt.Sprintf("?StopID=%d", id) +
			"&ReturnList=LineName,DestinationName,EstimatedTime,ExpireTime")

		var ps = []Prediction{}

		scanner := bufio.NewScanner(res.Body)

		if !scanner.Scan() {

		}

		_ = scanner.Bytes()

		for scanner.Scan() {
			line := scanner.Bytes()

			var p Prediction
			err = json.Unmarshal(line, &p)
			if err != nil {
				continue
			}

			delta := time.Until(p.EstimatedTime)

			p.Delta = int(delta / 1e9) // to secs
			p.DeltaString = delta.Truncate(time.Second).String()

			ps = append(ps, p)
		}

		sort.Slice(ps, func(a, b int) bool {
			return ps[a].EstimatedTime.Before(ps[b].EstimatedTime)
		})

		if limit > len(ps) || limit == 0 {
			limit = len(ps)
		}

		c.JSON(200, ps[:limit])
	})

	r.Run() // listen and serve on 0.0.0.0:8080 (for windows "localhost:8080")
}

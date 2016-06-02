#!/usr/bin/env python

import json
import requests

from wsgiref.simple_server import make_server
from cgi import parse_qs, escape
	

def get(environ, start_response):
	parameters = parse_qs(environ.get('QUERY_STRING', ''))
	
	url = 'http://ivu.aseag.de/interfaces/ura/instant_V1'
# url = 'http://countdown.api.tfl.gov.uk/interfaces/ura/instant_V1'
	
	r = requests.get(url, parameters)
	
	output = []
	for line in r.text.splitlines():
		print line
		output.append(json.loads(line))

	start_response('200 OK', [('Content-Type', 'application/json')])

	return json.dumps(output)

if __name__ == '__main__':
	srv = make_server('localhost', 8080, get)
	srv.serve_forever()
from http.server import BaseHTTPRequestHandler, HTTPServer
import ssl
import cgi
import urllib.parse
import lxml.etree as etree
import json
import simplejson
import sys
import os.path
import time
import datetime
import base64
import smtplib
import csv
from binascii import unhexlify


user = "deviot"
password = "loratest"
pstr = user + ":" + password

def csv_write (nodeUID,data):
	#convert data from hex to int
	data = unhexlify(data)
	#conver data from int to string
	data = data.decode("utf-8")
	#split data to classify OBIS code
	OBISCode = data.split(':')[0]
	#core value
	value_measured = data.split(':')[1]
	currentDate = str(datetime.datetime.now().day)
	currentMonth = str(datetime.datetime.now().month)
	currentYear = str(datetime.datetime.now().year)
	currentHour = str(datetime.datetime.now().hour)
	currentMinute = str (datetime.datetime.now().minute)
	# prepare time stamp
	dataToCsv = [[nodeUID, currentHour, currentMinute , OBISCode, value_measured]]
	filename = str(nodeUID)+"-"+currentDate+currentMonth+currentYear + ".csv"
	dir = '/IOT/'
	if not os.path.exists(dir):
	 columnTitle = [['UID', 'Hour', 'Minute','OBIS-CODE','DATA']]
	 os.mkdir(os.path.dirname(dir))
	 os.chdir(dir)
	 with open(filename , 'w') as csvFile:
		 writer = csv.writer(csvFile)
		 writer.writerows(columnTitle)
		 writer.writerows(dataToCsv)
		 csvFile.close()
	else:
	 with open(dir+filename , 'a') as csvFile:
		 writer = csv.writer(csvFile)
		 writer.writerows(dataToCsv)
		 csvFile.close()

# End of function

class testHTTPServer_RequestHandler(BaseHTTPRequestHandler):

    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        self._set_headers()
        message = "<html><body><h1>hi!</h1></body></html>"
        self.wfile.write(bytes(message, "utf8"))

    def do_HEAD(self):
        self._set_headers()

    def do_POST(self):
        self._set_headers()
        print(self.headers)
        ctype, pdict = cgi.parse_header(
            self.headers['Content-type'])  ## Classify application type
        print(pdict)
        if ctype == 'application/json':
            # load header in to a string
            data_string = self.rfile.read(int(self.headers['Content-Length']))
            print(data_string)
            # convert json to python format
            postvars = json.loads(data_string)
            # print(postvars)
            # keys captures
            keys = postvars.keys()
            print(keys)
            # classify the data object
            postdata = json.loads(postvars['data'])
            # print(postdata)
            # classify core data (data from meter)
            finaldata = postdata['data']
            # finaldata = int(finaldata,16)
            print("Data: ")
            print(finaldata)
            # collecting device EUI
            LoraDevEui = postdata['EUI']
            print("LoraDevEui: ")
            print(LoraDevEui)
            # collecting which port
            LoraPort = postdata['port']
            print("LoraPort: ")
            print(LoraPort)
            # collect keys (dictionaries)
            csv_write(LoraDevEui,finaldata)

def run():
    print('starting server...')
    server_address = ('0.0.0.0', 80)
    httpd = HTTPServer(server_address, testHTTPServer_RequestHandler)
    print('running server...')
    httpd.serve_forever()
run()
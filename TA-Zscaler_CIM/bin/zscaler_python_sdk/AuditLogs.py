
import json
import csv
import logging
import sys
import time
from pprint import pprint
import inspect

class AuditLogs(object):

	def get_audit_report(self, output = "raw"):
		#Can be called for upto 3 return types.  RAW output (full response. object), CSV (with headers row) or JSON

		uri = self.api_url + 'api/v1/auditlogEntryReport/download'

		res = self._perform_get_request(
			uri,
			self._set_header(self.jsessionid)
		)

		if self.debug:
			logging.debug("API RESPONSE -\n"+res.text)

		if output == "raw":
			#return full response object, easy
			return res

		if output == "csv":
			index = 0
			csvdata = ""

			for line in res.text.splitlines():
				if index > 3:
					csvdata += line + "\n"
					
				index += 1

			return csvdata

		if output == "json":
			index = 0
			csvdata = ""


			for line in res.text.splitlines():
				if index > 3:
					csvdata += line + "\n"
					#print(line)
					
				index += 1

			#reader = csv.DictReader(res.text)
			reader = csv.DictReader(csvdata.splitlines())

			jsondata = json.dumps([row for row in reader], indent=2)

			return jsondata


	def parse_blob(self, blob):
		actions = {}
		return actions

	def generate_audit_report(self, start, end, retry=True):

		uri = self.api_url + 'api/v1/auditlogEntryReport'

		body = {
			"startTime": start,
			"endTime": end,
 			"page": 1,
			"pageSize": 100
		}

		res = self._perform_post_request(
			uri,
			body,
			self._set_header(self.jsessionid)
		)

		#HANDLE JSON Response
		# Sample Response when rate-liomited (see next line)
		# {'message': 'Rate Limit (2/SECOND) exceeded', 'Retry-After': '0 seconds'}
		# Rate limiting returne HTPT Status Code: 429

		#data = res.json()

		#if res.response is 429:
		#	logging.debug("Over Rate Limit")
		#	if retry:
		#		while res.response is 429:
		#			time.sleep(5)
		#			logging.debug("Over Rate Limit - trying again")
		#			res = self._perform_post_request(
		#			uri,
		#			body,
		#			self._set_header(self.jsessionid)
		#		)
		#	else:
		#		return False

		return res



	def check_audit_status(self):

		uri = self.api_url + 'api/v1/auditlogEntryReport'

		res = self._perform_get_request(
			uri,
			self._set_header(self.jsessionid)
		)

		if self.debug:
			logging.debug("\n\n ##########  Getting API RESPONSE  ##########\n\n")
		
		# HANDLE JSON Response
		# Sample Response when rate-liomited (see next line)
		# {'message': 'Rate Limit (2/SECOND) exceeded', 'Retry-After': '0 seconds'}
		# Rate limiting returne HTTP Status Code: 429

		#if res.status_code == 404:
		#	return False
		#print(res.status_code)

		#pprint(res)
		data = res.json()
		logging.debug(data)


		return data['status']
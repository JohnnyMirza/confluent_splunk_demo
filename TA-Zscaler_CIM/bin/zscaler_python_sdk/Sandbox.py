
import json
import time
import logging
import os
from pprint import pprint


class Sandbox(object):


	def get_sandbox_report(self, md5, details="summary"):
		#by default we'll get summary report.  Caller can override by supplying "full" as arg2

		uri = self.api_url + 'api/v1/sandbox/report/' + md5 + "?details=" + details

		# check we can call for MD5 data, or are we over quota
		# will full response object if we have quota, itherwise loop until we get a slot
		# need to add better handling for being over quota
		quota = self.check_sandbox_quota()
		print(quota)
		#ew.log("INFO", "Sandbox current quota : %s" % quota)

		if quota['unused'] > 0:
			res = self._perform_get_request(
			uri,
			self._set_header(self.jsessionid)
			)
			return res
		else:
			time.sleep(1)

			while quota['unused'] > 0:
				quota = self.check_sandbox_quota()
				#ew.log("INFO","waiting 1 sec...\tquota_left[" + str(quota['unused']) + "']")
				
				time.sleep(1)



		res = self._perform_get_request(
			uri,
			self._set_header(self.jsessionid)
		)
		return res

	def check_sandbox_quota(self):
		# Get sandbox quota and retuen JSON 

		uri = self.api_url + 'api/v1/sandbox/report/quota'

		res = self._perform_get_request(
			uri,
			self._set_header(self.jsessionid)
		)

		#print(res.content)
		data = json.loads(res.content)
		#pprint(data)
		unused = data[0]
		return unused



# encoding = utf-8

import os
import sys
import time
import datetime
import zscaler_python_sdk
import splunklib.results as results
from splunklib.modularinput import *
import splunklib.client as client
import json

'''
    IMPORTANT
    Edit only the validate_input and collect_events functions.
    Do not edit any other part in this file.
    This file is generated only once when creating the modular input.
'''
'''
# For advanced users, if you want to create single instance mod input, uncomment this method.
def use_single_instance_mode():
    return True
'''

def validate_input(helper, definition):
    """Implement your own validation logic to validate the input stanza configurations"""
    # This example accesses the modular input variable
    # cloud = definition.parameters.get('cloud', None)
    # apikey = definition.parameters.get('apikey', None)
    # global_account = definition.parameters.get('global_account', None)
    pass

def get_md5_list(sername, password, session_key):
    args = {'token':session_key}
    
    #service = client.connect(host="127.0.0.1", port=8089, username="zscaler", password="fakepass")
    service = client.connect(**args)
    kwargs_oneshot = {"earliest_time": "-1h", "latest_time": "now",}
    searchquery_oneshot = "| inputlookup zscaler-md5-lookup.csv | dedup md5"
    oneshotsearch_results = service.jobs.oneshot(searchquery_oneshot, **kwargs_oneshot)
    return oneshotsearch_results
    
    '''
    try:
        service = client.connect(host="127.0.0.1", port=8089, username="zscaler", password="Zscal3r!")
        #service = client.connect(**args)
        kwargs_oneshot = {"earliest_time": "-1h", "latest_time": "now",}
        searchquery_oneshot = "| inputlookup zscaler-md5-lookup.csv | dedup md5"
        oneshotsearch_results = service.jobs.oneshot(searchquery_oneshot, **kwargs_oneshot)
        return oneshotsearch_results

    except Exception as e:
        raise Exception, "Boo!: %s" % str(e)
    '''

def collect_events(helper, ew):
    global_account = helper.get_arg('global_account')
    cloud = helper.get_arg('cloud')
    api_key = global_account['api_key']
    username = global_account['username']
    password = global_account['password']

    # Get list of MD5's pending detonation
    #session_key = helper.get_arg('session_key')
    #input_name, input_items = inputs.inputs.popitem()
    session_key = helper.context_meta['session_key']
    #session_key = "dummy"
    md5List = get_md5_list(username, password, session_key)

    #Set envvars based on clear creds
    #os.environ["ZIA_USERNAME"] = username
    #os.environ["ZIA_PASSWORD"] = password
    #os.environ["ZIA_API"] = api_key

    #API Login
    helper.log_info("Login to Zscaler API: %s" % username)

    z = zscaler_python_sdk.zscaler()
    z.get_settings_from_vars(username, password, api_key)
    z.set_cloud(cloud)
    z.authenticate_zia_api()

    helper.log_info("Login Success")

    # Get the results and display them using the ResultsReader
    reader = results.ResultsReader(md5List)
    for item in reader:
        if(item["md5"] == "none"):
            helper.log_info("STOP: No queued MD5")
            break
        helper.log_info("Checking Zscaler Sandbox for MD5 : %s" % item["md5"])
        quota = z.check_sandbox_quota()
        #print(quota)
        helper.log_info("Sandbox current quota : %s" % quota)

        while quota['unused'] <= 0:
            quota = z.check_sandbox_quota()
            helper.log_info("waiting 1 sec...\tquota_left[" + str(quota['unused']) + "']")
            
            time.sleep(1)

        helper.log_info("Loading Zscaler Sandbox for MD5 : %s" % item["md5"])
        report = z.get_sandbox_report(item["md5"], "full")
        #helper.log_info("Sandbox REPORT : %s" % report.text)
        #print(item["md5"])
        #event = Event()
        #event.stanza = input_name
        #event.data = report.text
        
        if ("Please try again later" in report.text):
            helper.log_info("Sandbox REPORT for MD5(" + item["md5"]  + "): " + report.text)
        else:
            event = helper.new_event(report.text)
            ew.write_event(event)


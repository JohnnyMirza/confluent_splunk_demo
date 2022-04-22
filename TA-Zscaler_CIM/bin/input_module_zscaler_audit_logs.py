
# encoding = utf-8

import os
import sys
import time
import datetime
import json
import xml
import zscaler_python_sdk

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
    # global_account = definition.parameters.get('global_account', None)
    # cloud = definition.parameters.get('cloud', None)
    pass

def collect_events(helper, ew):
    global_account = helper.get_arg('global_account')
    cloud = helper.get_arg('cloud')
    api_key = global_account['api_key']
    username = global_account['username']
    password = global_account['password']
    file = "checkpoint"

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

    # Set Proxies for Reqests 
	#"http”: "http://1.2.3.4:8000”="",
 	#"https”: "http://1.2.3.4:8000",
    z.proxies = {
		"http": "",
 		"https": "",
	}

    helper.log_info("Login Success")

    # Get Audit Report

    #load starttime from checkpoint file
    helper.log_debug("Loading Checkpoint: " + file)
    stime = helper.get_check_point(file)
    #if we get no time for checpoint default to 10 mins ago
    if(not stime):
        #set strt time a week ago, end time now
        helper.log_debug("Cant determine last execution time, using default [last 10 mins]")
        startOffset = 604800
        stime = int(round(time.time() * 1000)-startOffset)-1000

    etime = int(round(time.time() * 1000)) -1000

    helper.log_info("Generating Report: " + str(stime) + "-" + str(etime))
    generate = z.generate_audit_report(stime, etime)
    helper.log_info("Report generated status(" + str(generate.status_code) + ") :" + str(generate.text))
        #	print("\n\n ##########  GENERATING API RESPONSE  ##########")
    #print(generate)
    #if generate is "Status Code: 204":
        #print("\n\n ##########  GENERATING AUDIT REPORT SUCCESS  ##########\n\n" + generate)
    #else:
        #print("\n\n ##########  FAILED TO GENERATE REPORT  ##########\n\n" + generate)
        #return
    
    #if generate is not "Status Code: 204":
    #	helper.log_info("API Error: " + str(generate.text))
    #	return
    
    status = z.check_audit_status() 
    #print(status + "\n")
    
    #don't try to download report while status is executing
    #there's more response types for this call we could look to handle too.  
    while status == "EXECUTING":
        status=z.check_audit_status() 
        helper.log_info("Looping Audit Log still generating, ServerSideStatus=" + status)
        
        time.sleep(1)

    ew.log("INFO","##########  AUDIT REPORT GENERATED  ##########\n\n")

    report = z.get_audit_report("json")
    helper.log_debug("REPORT: " + report)
    #event = helper.new_event(report)   
    #ew.write_event(event)
    logs = json.loads(report)

    for log in logs:
        helper.log_info("EVENT: " + json.dumps(log))
        event = helper.new_event(json.dumps(log)) 
        ew.write_event(event)


    #for line in report:
        #helper.log_debug("LINE: " + line)

        #if(key == "log"):
            #for log in value:
                #helper.log_debug("Log: " + str(log))

        #event = helper.new_event(line)
        #ew.write_event(event)
    

    helper.log_debug("Saving Chekpoint: " + file)
    helper.save_check_point(file, etime)
    

    
    '''
    # The following examples show usage of logging related helper functions.
    # write to the log for this modular input using configured global log level or INFO as default
    helper.log("log message")
    # write to the log using specified log level
    helper.log_debug("log message")
    helper.log_info("log message")
    helper.log_warning("log message")
    helper.log_error("log message")
    helper.log_critical("log message")
    # set the log level for this modular input
    # (log_level can be "debug", "info", "warning", "error" or "critical", case insensitive)
    helper.set_log_level(log_level)
    '''


    '''
    # The following examples show usage of check pointing related helper functions.
    # save checkpoint
    helper.save_check_point(key, state)
    # delete checkpoint
    helper.delete_check_point(key)
    # get checkpoint
    state = helper.get_check_point(key)

    # To create a splunk event
    helper.new_event(data, time=None, host=None, index=None, source=None, sourcetype=None, done=True, unbroken=True)
    '''

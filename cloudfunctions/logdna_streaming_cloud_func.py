"""Event Streams producer.
/*
* Copyright IBM Corp. 2017, 2021 All Rights Reserved.
* Licensed under the Apache Public License v2.0
*/
"""
import base64
import logging
import math
import os
import ssl
import sys
import time
import traceback
import requests
import urllib.request
from datetime import datetime
from kafka import KafkaProducer
from kafka.errors import NoBrokersAvailable, KafkaTimeoutError, AuthenticationFailedError
from kafka.version import __version__
from random import shuffle
logging.basicConfig(stream=sys.stdout, level=logging.INFO,
                    format='%(levelname)-8s %(asctime)s %(message)s',
                    datefmt='[%H:%M:%S]')
max_cached_producers = 10
def main(params):
    producer = None
    logging.info("Using kafka-python %s", str(__version__))
    logging.info("Validating parameters")
    validationResult = validateParams(params)
    if validationResult[0] != True:
        return {'error': validationResult[1]}
    else:
        validatedParams = validationResult[1]
    ct = int(datetime.timestamp(datetime.now()))
    ct = ct-(ct % 60)-(int(validatedParams['back_time_in_min'])*60)
    logging.info("Previous rounded of by minute timestamp: "+str(ct))
    i = 0
    all_logs = []
    msg=""
    result = {"success": True}
    # Number of partitions of one minute
    p = 12
    retry_Limit = 2
    while(i < p):
        retry_count = 0
        st = (60/p)*(p-i)-0.001
        et = (60/p)*(p-(i+1))
        values = logFetch(ct-st, ct-et, validatedParams)
        retry_flag = False

        if  values == None:
            retry_flag = True
        if retry_flag != True:
            if values.status != 200:
                retry_flag = True

        while (retry_flag == True) and retry_count < retry_Limit:
            retry_count += 1
            logging.info("retrying counter:" + str(retry_count) + " and partition number:" + str(i+1))
            values=logFetch(ct-st,ct-et, validatedParams)
            if  values == None:
                continue
            if values.status != 200:
                continue
            retry_flag = False
        if values == None:
            i = i + 1
            continue
        if values.status == 200:
            contents = values.read()
            contents = contents.decode("utf-8")
            values = contents.split("\n")
            l = len(values)-1
            logging.info("values fetched in"+str(i+1)+"th API call"+str(l))
            all_logs.extend(values[:-1])
        else:
            logging.info("Getting error having status code: " +
                            str(values.status)+"for "+str(i+1)+"th API call.")
        i = i + 1
    if len(all_logs) > 0:
        attempt = 0
        max_attempts = 2
        while attempt < max_attempts:
            attempt += 1
            logging.info("Starting attempt {}".format(attempt))
            try:
                logging.info("Getting producer")
                # set a client timeout that allows for 2 connection retries while still
                # reserving 20s for the actual send
                producer_timeout_ms = math.floor(
                    getRemainingTime(reservedTime=10) / max_attempts * 1000)
                producer = getProducer(validatedParams, producer_timeout_ms)
                topic = validatedParams['topic']
                logging.info("Finding topic {}".format(topic))
                partition_info = producer.partitions_for(topic)
                logging.info("Found topic {} with partition(s) {}".format(
                    topic, partition_info))
                break
            except Exception as e:
                if attempt == max_attempts:
                    producer = None
                    logging.warning(e)
                    traceback.print_exc(limit=5)
                    result = getResultForException(e)
                    msg="Producer not found."
        # we successfully connected and found the topic metadata... let's send!
        if producer is not None:
            try:
                logging.info("Producing message")
                for value in all_logs:
                    future = producer.send(topic, bytes(
                        value, 'utf-8'))
                # future should wait all of the remaining time
                future_time_seconds = math.floor(getRemainingTime())
                sent = future.get(timeout=future_time_seconds)
                msg = "Successfully sent message to {}:{} at offset {}".format(
                    sent.topic, sent.partition, sent.offset)
                result = {"success": True, "message": msg,
                          "Time": str(ct), "Length": len(all_logs)}
            except Exception as e:
                logging.warning(e)
                traceback.print_exc(limit=5)
                result = getResultForException(e)
    else:
        msg = "No Logs Found"
        result = {"success": False, "message": msg,
                  "Time": str(ct), "Length": len(all_logs)}
    logging.info(msg)
    return result
def logFetch(ft, tt, validatedParams):
    size = 10000
    url = "https://api."+validatedParams['region_name']+".logging.cloud.ibm.com/v1/export?to="+str(tt)+"&&from="+str(ft)+"&&size="+str(size)+"&&prefer=head"
    try:
        response = urllib.request.urlopen(urllib.request.Request(url,headers={"Authorization": 'Basic ' +validatedParams['logdna_service_key']}))
    except Exception as e:
        logging.warning(e)
        traceback.print_exc(limit=5)
        time.sleep(1)
        return None
    return response
def getResultForException(e):
    if isinstance(e, KafkaTimeoutError):
        return {'error': 'Timed out communicating with Message Hub'}
    elif isinstance(e, AuthenticationFailedError):
        return {'error': 'Authentication failed'}
    elif isinstance(e, NoBrokersAvailable):
        return {'error': 'No brokers available. Check that your supplied brokers are correct and available.'}
    else:
        return {'error': '{}'.format(e)}
def validateParams(params):
    validatedParams = params.copy()
    requiredParams = ['kafka_brokers_sasl', 'user', 'password',
                      'topic', 'region_name', 'logdna_service_key', 'back_time_in_min']
    missingParams = []
    for requiredParam in requiredParams:
        if requiredParam not in params:
            missingParams.append(requiredParam)
    if len(missingParams) > 0:
        return (False, "You must supply all of the following parameters: {}".format(', '.join(missingParams)))
    if isinstance(params['kafka_brokers_sasl'], str):
        # turn it into a List
        validatedParams['kafka_brokers_sasl'] = params['kafka_brokers_sasl'].split(
            ',')
    shuffle(validatedParams['kafka_brokers_sasl'])
    if 'base64DecodeKey' in params and params['base64DecodeKey'] == True:
        try:
            validatedParams['key'] = base64.b64decode(
                params['key']).decode('utf-8')
        except:
            return (False, "key parameter is not Base64 encoded")
        if len(validatedParams['key']) == 0:
            return (False, "key parameter is not Base64 encoded")
    return (True, validatedParams)
def getProducer(validatedParams, timeout_ms):
    connectionHash = getConnectionHash(validatedParams)
    if globals().get("cached_producers") is None:
        logging.info("dictionary was None")
        globals()["cached_producers"] = dict()
    # remove arbitrary connection to make room for new one
    if len(globals()["cached_producers"]) == max_cached_producers:
        poppedProducer = globals()["cached_producers"].popitem()[1]
        poppedProducer.close(timeout=1)
        logging.info("Removed cached producer")
    if connectionHash not in globals()["cached_producers"]:
        logging.info("cache miss")
        # create a new connection
        sasl_mechanism = 'PLAIN'
        security_protocol = 'SASL_SSL'
        # Create a new context using system defaults, disable all but TLS1.2
        context = ssl.create_default_context()
        context.options &= ssl.OP_NO_TLSv1
        context.options &= ssl.OP_NO_TLSv1_1
        producer = KafkaProducer(
            api_version=(0, 10),
            batch_size=1000000,
            bootstrap_servers=validatedParams['kafka_brokers_sasl'],
            max_block_ms=timeout_ms,
            request_timeout_ms=timeout_ms,
            sasl_plain_username=validatedParams['user'],
            sasl_plain_password=validatedParams['password'],
            security_protocol=security_protocol,
            ssl_context=context,
            sasl_mechanism=sasl_mechanism
        )
        logging.info("Created producer")
        # store the producer globally for subsequent invocations
        globals()["cached_producers"][connectionHash] = producer
        # return it
        return producer
    else:
        logging.info("Reusing existing producer")
        return globals()["cached_producers"][connectionHash]
def getConnectionHash(params):
    apiKey = "{}:{}".format(params['user'], params['password'])
    return apiKey
# return the remaining time (in seconds) until the action will expire,
# optionally reserving some time (also in seconds).
def getRemainingTime(reservedTime=10):
    deadlineSeconds = int(os.getenv('__OW_DEADLINE', 60000)) / 1000
    remaining = deadlineSeconds - time.time() - reservedTime
    # ensure value is at least zero
    # yes, this is a little paranoid
    return max(remaining, 0)
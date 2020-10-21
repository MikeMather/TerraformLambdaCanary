import sys
sys.path.insert(0, 'package/')

import boto3
import os
import requests
from datetime import datetime

TARGET_SITE = os.environ.get('TARGET_SITE', 'http://localhost')
NOTIFICATION_NUMBER = os.environ['NOTIFICATION_NUMBER']

def notify():
    sns = boto3.client('sns')
    sns.publish(
        Message=f'Canary check failed.', 
        PhoneNumber=NOTIFICATION_NUMBER
    )

def ping(event, context):
    try:
        res = requests.get(TARGET_SITE)
        if not res.status_code == 200:
            notify()
        else:
            print(f'Check passed with status code {res.status_code}')
            return event['time']
    except Exception as e:
        print(e)
        notify()
    print(f'Check complete at {str(datetime.now())}')

if __name__ == '__main__':
    ping(None, None)
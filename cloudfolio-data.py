import subprocess
import sys
import json
import boto3

#subprocess.check_call([sys.executable, "-m", "pip", "install", "--target", "/tmp", 'yfinance'])
#sys.path.append('/tmp')
import yfinance as yf


def get_portfolio():
    pass


def lambda_handler(event, context):

    print(get_portfolio())

    return {
    'statusCode': 200,
    'body': json.dumps('Lambda execution completed!')
    }

event = 0
context = 0
lambda_handler(event,context)
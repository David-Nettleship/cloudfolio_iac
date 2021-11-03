import subprocess
import sys
import boto3
from datetime import date

# comment 2 lines below for local testing
subprocess.check_call([sys.executable, "-m", "pip", "install", "--target", "/tmp", 'yfinance'])
sys.path.append('/tmp')
import yfinance as yf

def get_portfolio(client):

    response = client.scan(TableName='cloudfolio-data')
    res = response['Items']

    tickers = []
    quant = []
    
    for r in res:

        tickers.append(r['Ticker']['S'])
        quant.append(r['Quantity']['N'])
    
    folio = dict(zip(tickers, quant))

    return folio


def get_close(portfolio):

    folio = []

    for p in portfolio:

        t = yf.Ticker(p)

        # get last close
        hist = t.history(period="1d")

        # get asset currency & name
        info = t.info
        currency = info['currency']
        name = info['longName']

        asset = {'name': name, 'ticker': p, 'quant': float(portfolio.get(p)), 'close': hist["Close"][0], 
               'currency': currency}
        folio.append(asset)

    return folio


def calc_values(portfolio):

    folio = []

    # get GBP/USD conversion rate
    conversion = yf.Ticker('GBP=X')
    rate = conversion.history(period="1d")
    rate = rate["Close"][0]

    for p in portfolio:

        if p['currency'] == 'USD':
            value = round((p['quant'] * p['close'])*rate,2)
        
        elif p['currency'] == 'GBp':
            value = round((p['quant'] * p['close'])/100,2)

        obj = {'name': p['name'], 'ticker': p['ticker'], 'quant': p['quant'], 'close': p['close'], 'value': value}
        folio.append(obj)
    
    return folio


def update_portfolio(portfolio, client):

    today = str(date.today())

    for p in portfolio:
        
        client.put_item(TableName='cloudfolio-values', Item={'Date': {
            'S': today}, 'Ticker':{'S': p['ticker']}, 'Name':{'S': p['name']}, 'Quantity':{'S': str(p['quant'])}, 
            'Value':{'S': str(p['value'])}, 'Close':{'S': str(round(p['close'],2))}})


def lambda_handler(event, context):

    client = boto3.client('dynamodb')

    # read from cloudfolio-data
    portfolio = get_portfolio(client)

    # get latest value from YahooFinance
    portfolio = get_close(portfolio)

    # calculate latest value of asset(s)
    portfolio = calc_values(portfolio)

    # write to cloudfolio-values
    update_portfolio(portfolio, client)


# uncomment lines for local testing
#event = 0
#context = 0
#lambda_handler(event,context)

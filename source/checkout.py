import random
import re
import sys
import requests
import os
import json
from flask import Flask, render_template, json, jsonify

app = Flask(__name__)
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

@app.route('/checkout')
def checkout():
    response1 = requests.get("http://10.0.113.15:8994/productcatalog")
    response2 = requests.get("http://10.0.113.16:8995/shipping")
    response3 = requests.get("http://10.0.113.17:8996/currency")
    response4 = requests.get("http://10.0.113.13:8992/payment")
    response5 = requests.get("http://10.0.113.14:8993/emails")
    response6 = requests.get("http://10.0.113.18:8997/carts")
    with open('./templates/checkout.json', 'r') as myfile:
        data = myfile.read()
    return response1.text + response2.text + response3.text + response4.text + response5.text + response6.text + data

if __name__ == '__main__':
    app.run(host='0.0.0.0',port=8989,debug=True)

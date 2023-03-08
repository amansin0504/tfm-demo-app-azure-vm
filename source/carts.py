import random
import re
import sys
import requests
import os
import json
from flask import Flask, render_template, json, jsonify

app = Flask(__name__)
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

@app.route('/carts')
def checkout():
    response1 = requests.get("http://10.0.115.10:8998/redis")
    with open('./templates/carts.json', 'r') as myfile:
        data = myfile.read()
    return response1.text + data

if __name__ == '__main__':
    app.run(host='0.0.0.0',port=8989,debug=True)

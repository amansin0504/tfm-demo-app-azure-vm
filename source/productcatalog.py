import random
import re
import sys
from flask import Flask, render_template

app = Flask(__name__)
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

@app.route('/productcatalog')
def productcatalog():
    return render_template('productcatalog.json')

if __name__ == '__main__':
    app.run(host='localhost',port=8994,debug=True)

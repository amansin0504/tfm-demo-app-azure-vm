#!/bin/bash
sudo apt update
sudo apt install python3-pip -y
sudo apt install wget
sudo pip install Flask

git clone https://github.com/amansin0504/csw-vm-demo.git
mkdir app/
mkdir app/templates
cp csw-vm-demo/source/emails.py app/app.py
cp csw-vm-demo/source/templates/email.json app/templates/
cd app
flask run  --host=0.0.0.0 -p 8993&

#!/bin/bash
sudo apt update
sudo apt install python3-pip -y
sudo apt install wget
sudo pip install Flask

git clone https://github.com/amansin0504/tfm-demo-app-azure-vm.git
mkdir app/
mkdir app/templates
cp tfm-demo-app-azure-vm/source/frontend.py app/app.py
cp tfm-demo-app-azure-vm/source/templates/index.html app/templates/
cd app
sudo flask run  --host=0.0.0.0 -p 8080&

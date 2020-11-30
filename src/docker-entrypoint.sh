#!/bin/bash

# install python3 / pip
apt update
apt install -y python3 python3-pip libpq-dev

# install dependencies
python3 -m pip install -r /database/requirements.txt

# run original entrypoint script
/docker-entrypoint.sh postgres
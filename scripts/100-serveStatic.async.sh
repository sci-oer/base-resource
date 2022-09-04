#!/bin/bash

# This will serve all the static content
python3 /scripts/server.py -d /opt/static/ --proxy-url "$REMOTE_STATIC_SERVER_URL" 8000

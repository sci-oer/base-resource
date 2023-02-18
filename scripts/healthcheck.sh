#!/bin/bash

# check wiki
curl -s -f http://localhost:3000/healthz >/dev/null || exit 1
echo "wiki is up"

# check static
curl -s -f http://localhost:8000/ >/dev/null || exit 1
echo "static is up"

# check jupyter
curl -s -f http://localhost:8888/api >/dev/null|| exit 1
echo "jupyter is up"

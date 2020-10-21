#!/bin/bash

# Install requirements into the package directory
cd "$(dirname "$0")"
python3 -m pip install -r requirements.txt -t package/
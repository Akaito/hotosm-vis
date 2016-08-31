#!/bin/bash

curl -L -X POST --data @node-query.ql http://overpass-api.de/api/interpreter --header "Content-Type:text/plain"


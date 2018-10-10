#!/usr/bin/env bash

yum install -y epel-release
yum install -y stress
yum install htop wget

#run 8 workers spinning on sqrt() with a timeout of 400 seconds
stress --cpu 8 -v --timeout 400
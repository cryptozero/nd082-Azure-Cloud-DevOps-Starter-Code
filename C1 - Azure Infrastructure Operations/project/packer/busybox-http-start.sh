#!/bin/bash

echo 'Hello, World!' > index.html
pwd >> home.html
nohup busybox httpd -f -p 80 &
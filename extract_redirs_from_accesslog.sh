#!/bin/bash

# set the paths to your access log and output file
access_log="/var/log/apache/access-nginx.log"
output_file="/root/RM/output.txt"

# set the domains to search for redirects
domains=("example1.com" "example2.com")

# search for http redirects to the specified domains in the access log and output them to the output file
for domain in "${domains[@]}"; do
  grep -E "HTTP\/[0-9\.]+\" (30[1-38]|307)" $access_log | grep -E "\b$domain\b" >> $output_file
done

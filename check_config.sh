#!/bin/bash

config_file="/etc/mysql/my.cnf"

# Output directory for temporary files
output_dir="/tmp/check_config"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Get the list of servers from the configuration file
servers=($(cat /etc/icinga2/gds138db.list))

# Exit status of the script (0 - OK, 2 - Critical)
exit_status=0

# Compare configuration among servers
for ((i=0; i<${#servers[@]}; i++))
do
  for ((j=i+1; j<${#servers[@]}; j++))
  do
    server1="${servers[$i]}"
    server2="${servers[$j]}"
    file1="$output_dir/$server1.tmp"
    file2="$output_dir/$server2.tmp"

    # Download the configuration file from the remote server using scp
    scp "$server1:$config_file" "$file1"
    scp "$server2:$config_file" "$file2"

    # Check if the configuration files are not empty
    if [ -s "$file1" ] && [ -s "$file2" ]; then
      # Compare the configuration files
      if diff -q "$file1" "$file2" >/dev/null 2>&1; then
        echo "OK: Configuration files are the same between $server1 and $server2."
      else
        echo "Critical: Configuration files differ between $server1 and $server2."
        diff -u "$file1" "$file2"
        exit_status=2
      fi
    else
      echo "Error: Configuration file is empty on server $server1 or $server2."
      exit_status=2
    fi
  done
done

# Remove temporary files
rm -f "$output_dir"/*.tmp

# Exit with the script's exit status
exit "$exit_status

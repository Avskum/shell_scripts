#!/bin/bash

# Initialize variables to store the inputs
summary=""
description=""
monitoring=""

# Function to show script usage
usage() {
    echo "Usage: $0 -s 'short summary/title' -d 'detailed problem description' -m 'Yes/No'"
    echo "All inputs are required, summary can be max 45 characters long, -m can only be 'Yes' or 'No'"
    exit 1
}

#if no input script will end and show usage - needed due to limited failed requests which can be made on JIRA API
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

# Use getopts to grab inputs from the command line
while getopts ":s:d:m:h" opt; do
  case $opt in
    s)
        if [[ -z "$OPTARG" ]]; then
            echo "Input for option -s cannot be blank" >&2
            usage
        elif [[ ${#OPTARG} -gt 45 ]]; then
            echo "Input for option -s cannot be longer than 45 characters" >&2
            usage
        else
            summary="$OPTARG"
        fi
    ;;
    d)
        if [[ -z "$OPTARG" ]]; then
            echo "Input for option -d cannot be blank" >&2
            usage
        else
            description="$OPTARG"
        fi
    ;;
    m)
        if [[ -z "$OPTARG" ]]; then
            echo "Input for option -m cannot be blank" >&2
            usage
        elif [[ "$OPTARG" != "Yes" && "$OPTARG" != "No" && "$OPTARG" != "yes" && "$OPTARG" != "no" ]]; then
            echo "Invalid input for option -m, allowed inputs are Yes/No" >&2
            usage
        else
            monitoring="$OPTARG"
        fi
    ;;
    h) usage
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        usage
    ;;
  esac
done

#define datetime so it will be automaticly passed to json
datetime=$(date +%F)T$(date +"%I:%M:%S")


# Show the inputs in the console
echo "summary: $summary"
echo "description: $description"
echo "monitoring: $monitoring"
echo "datetime: $datetime"




project=PROJECT_NAME
email=api@domain.com
api_key=$(cat /etc/adm/jira_api_key)


curl -i -u $email:$api_key -H 'Content-Type: application/json' -XPOST --data '{"fields":{"project":{"key":"PROJECT_NAME"},"summary":"'"$summary"'","assignee":"'"$assignee"'","customfield_10201":"'"$datetime"'","customfield_12100":{"value":"'"$monitoring"'"},"description":{"type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"'"$description"'"}]}]},"issuetype":{"name":"Outage"}}}' https://yourname.atlassian.net/rest/api/3/issue ; echo

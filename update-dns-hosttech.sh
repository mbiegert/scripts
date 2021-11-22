#!/bin/bash

set -euo pipefail

# This script updates the dynamic dns entries for this network by directly updating
# the DNS entry with hosttech.eu.
#
# The variables below are expected from the environment. Uncomment them here
# to overwrite or simply not rely on the environment.
#

# Set a file here that will hold the current ip address in between
# runs of the script. So that we know if the public ip address has changed.
#IP_FILE=$HOME/ip-file
# Hosttech works with zones and records, it's a DNS provider after all. So go figure out your zone id
# and create the record you want to keep up to date. Also get yourself an API Access Token!
#ZONE_ID=1234
#RECORD_ID=1234
#HOSTTECH_TOKEN=xxx

# make sure that we have the necessary parameters
if [ -z "${IP_FILE-}" ] || [ -z "${RECORD_ID-}" ] || [ -z "${ZONE_ID-}" ] || [ -z "${HOSTTECH_TOKEN-}" ]; then
	echo "Please provide IP_FILE, RECORD_ID, ZONE_ID and HOSTTECH_TOKEN variables."
	exit 1
fi

# First get the gateways current public IP address.
CURRENT_IP=$( curl --silent checkip.spdyn.de )


# Now try to read the last IP from a file that we defined above.
# read it from a file
if [ -e "$IP_FILE" ]; then
	read LAST_IP < "$IP_FILE"
else
	LAST_IP=""
fi

if [ "$CURRENT_IP" != "$LAST_IP" ]; then
	# build the json payload
	UPDATE_PAYLOAD="{\"ipv4\":\"$CURRENT_IP\",\"ttl\":600}"

	# try updating the IP
	RESULT=$( curl "https://api.ns1.hosttech.eu/api/user/v1/zones/$ZONE_ID/records/$RECORD_ID" \
		-X PUT \
		--no-progress-meter \
		-w "\nHTTP Response Code: %{response_code}" \
		-H "Accept: application/json" \
		-H "Authorization: Bearer $HOSTTECH_TOKEN" \
		-H "Content-Type: application/json" \
		-d "$UPDATE_PAYLOAD" )

	RES_CODE=$( echo "$RESULT" | tail -n1 | awk '{print $(NF);}')
	if [ "$RES_CODE" = 200 ]; then
		echo "Updated record $RECORD_ID from $LAST_IP to $CURRENT_IP."
		# save the new ip to file
		echo "$CURRENT_IP" > "$IP_FILE"
	else
		echo "Updating failed with result:"
		echo "$RESULT"
		exit 1
	fi
else
	echo "No update needed, IP hasn't changed."
fi


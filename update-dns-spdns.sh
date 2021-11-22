#!/bin/bash

set -euo pipefail

# This script updates the dynamic dns entries for this network using the secure point
# dynamic dns service: spdns.org
#
# The variables below are expected from the environment. Uncomment them here
# to overwrite or simply not rely on the environment.
#

# Set a file here that will hold the current ip address in between
# runs of the script. So that we know if the public ip address has changed.
#IP_FILE=$HOME/ip-file
# some other self explanatory options
#SP_HOSTNAME=somehost.spdns.org
#SP_TOKEN=xxxx-xxxx-xxxx

# make sure that we have the necessary parameters
if [ -z "${IP_FILE-}" ] || [ -z "${SP_HOSTNAME-}" ] || [ -z "${SP_TOKEN-}" ]; then
	echo "Please provide IP_FILE, SP_HOSTNAME and SP_TOKEN variables."
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
	# try updating the IP
	RESULT=$( curl --silent "https://update.spdns.de/nic/update?hostname=$SP_HOSTNAME&myip=$CURRENT_IP" --user "$SP_HOSTNAME:$SP_TOKEN" )
	RES_WORD=$( echo "$RESULT" | head -n1 | awk '{print $1;}')
	if [ "$RES_WORD" = "good" -o "$RES_WORD" = "nochg" ]; then
		echo "Updated host $SP_HOSTNAME from $LAST_IP to $CURRENT_IP."
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


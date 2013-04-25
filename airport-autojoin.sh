#!/usr/bin/env zsh
# automatically join WiFi networks
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2013-04-24
#
# URL:	https://github.com/tjluoma/airport-autojoin

debug () { echo "[debug] $@" }


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
####
####	EDIT THIS SECTION
####

	####
	####	You have to create a list of known SSIDs and Passwords
	####	This can either be done either in an external file or embedded in this script
	####

		# if you don't want to embed the information into this file, you can put it into a separate file instead
		# The syntax for the separate file is exactly the same as 'KNOWN_NETWORKS=' below.
KNOWN_NETWORKS_FILE="${HOME}/Dropbox/etc/known-networks.txt"

if [ -f "${KNOWN_NETWORKS_FILE}" -a -r "${KNOWN_NETWORKS_FILE}" ]
then
			# if this exists as a readable file
		source "${KNOWN_NETWORKS_FILE}"

else
		# Left column = SSID
		# Right column = Password
		# If there is no password, use "-"
	KNOWN_NETWORKS=(
					"Home"				"89382ashfa"

					"Work"				"0823u2j98dyumn"

					"Coffee House"		""

					"Jenny's Wifi"		"8675309"
					)
fi

####
####	You should not need to edit anything below this
####
####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
####|####|####|####|####|####|####|####|####|####|####|####|####|####|####

NAME="$0:t:r"

AIRPORT='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'

if [ ! -x "$AIRPORT" ]
then
		echo "$NAME: Failed to find the 'airport' command at $AIRPORT"
		exit 1

fi

alias airport="$AIRPORT"

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#

CURRENT_SSID=$(airport -I | /usr/bin/egrep 'AirPort: Off|^ *SSID: ' | /usr/bin/sed 's#^ *SSID: ##g')

if [[ "$CURRENT_SSID" != "" ]]
then

	if [[ "$CURRENT_SSID" == "AirPort: Off" ]]
	then
			echo "$NAME: AirPort is disabled. Quitting"
			exit 0

	else

			# Normally, this script will exit immediately if you are already connected to a Wi-Fi
			# network. Use the -f flag to 'force' it to continue.

		if [ "$1" != "-f" ]
		then
				echo "$NAME: Already connected to an AirPort network. Quitting"
				exit 0
		fi
	fi
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
# `networksetup` requires root as of 10.8 (IIRC, maybe 10.7) so this script must be run as root
#
#	I recommend calling this script via `launchd` anyway, so this shouldn't be an issue.
#	See https://github.com/tjluoma/airport-autojoin for details

if [ "`id -u`" != "0" ]
then
	echo "$0 must be run as root, re-running via 'sudo'"
	exec sudo "$0" "$@"
fi


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#	This is the function we'll use when we're ready to join a Wi-Fi network.

join_wifi_network () {

		DESIRED_SSID="$1"

		PASSWORD="$2"

		if [ "$PASSWORD" = "" ]
		then
				echo "$NAME: Trying to join $DESIRED_SSID using $DEVICE (no password)."
				RESULT=$(networksetup -setairportnetwork "${DEVICE}" "${DESIRED_SSID}" 2>&1)

		else
				echo "$NAME: Trying to join $DESIRED_SSID using $DEVICE ($PASSWORD)."
				RESULT=$(networksetup -setairportnetwork "${DEVICE}" "${DESIRED_SSID}" "${PASSWORD}" 2>&1)
		fi

		CURRENT_SSID=$(airport -I | /usr/bin/egrep 'AirPort: Off|^ *SSID: ' | /usr/bin/sed 's#^ *SSID: ##g')

		if [[ "$CURRENT_SSID" == "$DESIRED_SSID" ]]
		then
				echo "$NAME: Successfully joined $DESIRED_SSID"

				exit 0
		else
				echo "$NAME: Failed to join $DESIRED_SSID. networksetup result =\n$RESULT\n"

				return 1
		fi
}

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####

	# usually en0 or en1
DEVICE=$(networksetup -listallhardwareports 2>/dev/null | egrep -A1 -i 'Hardware Port: (Wi-Fi|AirPort)' | tr -d '\012' | awk '{print $NF}')

	# this will give us an array with all of the available SSIDs, one per line, with the SSID
	# starting at the left margin and ending at the right margin
IFS=$'\n' AVAILABLE_SSIDS=($(airport --scan | colrm 33 | egrep -v "SSID$" | sed 's#^ *##g'))

	# initialize a variable that we will use to test to see if we found any of our preferred SSIDs
FOUND=no

	# the (@) will make it so that the PASSWORD will be filled even if it's empty
	# see "Parameter Expansion Flags" in zshexpn:

for 	DESIRED_SSID	PASSWORD	in 		 "${(@)KNOWN_NETWORKS}"
do

		debug "DESIRED_SSID is >$DESIRED_SSID< and PASSWORD is >$PASSWORD<"


			# we check the SSIDs that we want against a list of all of the available SSIDs
			# note that we are using egrep with ^ and $ to match exactly

			# if a matching SSID is found, set the variable FOUND to yes and break out of loop
		echo "$AVAILABLE_SSIDS" | egrep -q "^${DESIRED_SSID}$"

		EXIT="$?"

		if [ "$EXIT" = "0" ]
		then

				echo "$NAME: Attempting to join ${DESIRED_SSID}..."

				join_wifi_network "${DESIRED_SSID}" "${PASSWORD}"

		else

				debug "The network $DESIRED_SSID is not currently available"

		fi
done


echo "$NAME: No preferred SSIDs matched:\n$AVAILABLE_SSIDS"

exit 1



fini || exit
#
#EOF

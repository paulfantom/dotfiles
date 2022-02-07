#!/bin/bash

: ${HOMEASSISTANT_ADDR:="https://home.ankhmorpork.thaum.xyz"}
: ${HOMEASSISTANT_SWITCH:="switch.tree"}
: ${HOMEASSISTANT_TOKEN:=""}

function light_on() {
	if [ "$LIGHT_STATE" == "on" ]; then
		return
	fi
	echo "Turning light ON"
	curl -k -X POST \
		-H "Authorization: Bearer ${HOMEASSISTANT_TOKEN}" \
		-H "Content-Type: application/json" \
		-d "{\"entity_id\": \"${HOMEASSISTANT_SWITCH}\"}" \
		"${HOMEASSISTANT_ADDR}/api/services/switch/turn_on" &>/dev/null
	LIGHT_STATE="on"
}

function light_off() {
	if [ "$LIGHT_STATE" == "off" ]; then
		return
	fi
	echo "Turning light OFF"
	curl -k -X POST \
		-H "Authorization: Bearer ${HOMEASSISTANT_TOKEN}" \
		-H "Content-Type: application/json" \
		-d "{\"entity_id\": \"${HOMEASSISTANT_SWITCH}\"}" \
		"${HOMEASSISTANT_ADDR}/api/services/switch/turn_off" &>/dev/null
	LIGHT_STATE="off"
}

function state_mic() {
	# pipewire will take at least 2 pcm streams for the mic
	if [ "$(grep owner_pid /proc/asound/card*/pcm*/sub*/status | wc -l )" -gt "1" ]; then
		return 1
	fi
	return 0
}

function state_cam() {
	if fuser /dev/video* &>/dev/null; then
		# Camera used
		return 1
	fi
	return 0
}

function check_state() {
	local mic cam ret

	ret=0
	# check 4 times in 1s interval to limit glitches
	for i in $(seq 1 5); do
		state_mic
		mic="$?"
		state_cam
		cam="$?"

		ret=$((ret+$mic))
		
		# Break early when nothing is used
		if [ "$mic" -eq "0" -a "$cam" -eq "0" ]; then
			return 0
		fi

		# Break early when both are used
		if [ "$mic" -eq "1" -a "$cam" -eq "1" ]; then
			return 1
		fi

		# Continue checking if at least one is used
		sleep 2
	done

	# Return mic state after all checks
	# This is because not all meetings will use camera, but all meetings will use microphone
	if [ "$ret" -gt 2 ]; then
		ret=1
	fi
	return "$ret"
}


# Main loop
echo "Starting OnAir light controler"

# Assuming light is off by default
LIGHT_STATE="off"
while : ; do
	# Do not handle OnAir light on weekends
	if [ "$(date +%u)" -gt "5" ]; then
		sleep 6h
		continue
	fi
	
	check_state
	ret="$?"
	if [ "$ret" -eq "1" ]; then
		# "Meeting is in progress. Turning light ON"
		light_on
	else
		# "Meeting finished. Turning light OFF"
		light_off
	fi
	sleep 5
done

#!/bin/bash

FILE="${1}"
THREADS="${2}"
TIMEOUT="${3}"
CMD="${4}"
NUM=$(wc -l ${FILE} | awk '{ print $1 }')
THREAD=0
NUMDOM=0
while read SUBDOMAIN; do
	PIDSTAT=0
	if [ $THREAD -lt $THREADS ]; then
		eval timeout ${TIMEOUT} ${CMD} 2>/dev/null &
		PIDS[$THREAD]="${!}"
		let THREAD++
		let NUMDOM++
		echo -ne "\r>Progress: ${NUMDOM} of ${NUM} ($(awk "BEGIN {printf \"%0.2f\",(${NUMDOM}*100)/${NUM}}")%)\r"
	else
		while [ ${PIDSTAT} -eq 0 ]; do
			for j in "${!PIDS[@]}"; do
				kill -0 "${PIDS[j]}" > /dev/null 2>&1
				PIDSTAT="${?}"
				if [ ${PIDSTAT} -ne 0 ]; then
					eval timeout ${TIMEOUT} ${CMD} 2>/dev/null &
					PIDS[j]="${!}"
					let NUMDOM++
					echo -ne "\r>Progress: ${NUMDOM} of ${NUM} ($(awk "BEGIN {printf \"%0.2f\",(${NUMDOM}*100)/${NUM}}")%)\r"
					break
				fi
			done
		done
	fi
done < ${FILE}
wait

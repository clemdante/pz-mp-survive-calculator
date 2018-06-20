#!/bin/bash

# pz-mp survive calculator
# Author : clemdante
# Version 0.1



#Main function
function processLogs {
	declare -A connectedTimestampArray
	declare -A timeSpendByPlayerArray
	declare -a resultPlayerStat

	logsDir=`eval echo ~$USER`/Zomboid/Logs/;

	for d in `find "$logsDir"* -maxdepth 1 -type d -exec echo {} \;` ; do
		#csvLog $d

		for f in $d/*user.txt ; do 
			while read line; do
				connectedRegex="^\[([0-9]{2}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\] [0-9]* \"([A-Za-z0-9_\-]+)\" fully connected"
				disconnectedRegex="^\[([0-9]{2}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\] [0-9]* \"([A-Za-z0-9_\-]+)\" disconnected"
				userDiedRegex="^\[([0-9]{2}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\] user ([A-Za-z0-9_\-]+) died"
				if [[ $line =~ $connectedRegex ]]; then
					#If a connection line is found
					convertedDate=`date -d ${BASH_REMATCH[1]:6:2}"-"${BASH_REMATCH[1]:3:2}"-"${BASH_REMATCH[1]:0:2}" "${BASH_REMATCH[1]:9:8} +%s`
					if [[ -z ${connectedTimestampArray[${BASH_REMATCH[2]}]} ]]; then
						connectedTimestampArray[${BASH_REMATCH[2]}]+=$convertedDate
					else
						connectedTimestampArray[${BASH_REMATCH[2]}]=$convertedDate
					fi
				elif [[ $line =~ $disconnectedRegex ]]; then
					#If a disconnection file is found
					convertedDate=`date -d ${BASH_REMATCH[1]:6:2}"-"${BASH_REMATCH[1]:3:2}"-"${BASH_REMATCH[1]:0:2}" "${BASH_REMATCH[1]:9:8} +%s`
					if [[ -z ${timeSpendByPlayerArray[${BASH_REMATCH[2]}]} ]]; then
						timeSpendByPlayerArray[${BASH_REMATCH[2]}]+=$((convertedDate-connectedTimestampArray[${BASH_REMATCH[2]}]))
					else
						timeSpendByPlayerArray[${BASH_REMATCH[2]}]=$((convertedDate-connectedTimestampArray[${BASH_REMATCH[2]}]+timeSpendByPlayerArray[${BASH_REMATCH[2]}]))
					fi
				elif [[ $line =~ $userDiedRegex ]]; then
					#If someone died(Only if player died because of Zeds)
					convertedDate=`date -d ${BASH_REMATCH[1]:6:2}"-"${BASH_REMATCH[1]:3:2}"-"${BASH_REMATCH[1]:0:2}" "${BASH_REMATCH[1]:9:8} +%s`
					timestampSpend=$((convertedDate-connectedTimestampArray[${BASH_REMATCH[2]}]+timeSpendByPlayerArray[${BASH_REMATCH[2]}]))
					timestampSpend=$((timestampSpend*24))
					playerStat=${BASH_REMATCH[2]}' Survive for '$((timestampSpend/60/60/24))" days "$((timestampSpend/60/60%24))" hours "$((timestampSpend/60%60))" minutes and "$((timestampSpend%60))" seconds"
					echo $playerStat
					resultPlayerStat+=($playerStat)	
					connectedTimestampArray[${BASH_REMATCH[2]}]="0"
					timeSpendByPlayerArray[${BASH_REMATCH[2]}]="0"
				fi
			done < $f
		done
	done
}

#Use to produce CSV file. Only output into the console for now
function csvLog {
	folder=$1
	for f in $folder/*user.txt ; do 
		while read line; do
			connectedRegex="^\[([0-9]{2}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\] [0-9]* \"([A-Za-z0-9_\-]+)\" fully connected"
			disconnectedRegex="^\[([0-9]{2}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\] [0-9]* \"([A-Za-z0-9_\-]+)\" disconnected"
			userDiedRegex="^\[([0-9]{2}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\] user ([A-Za-z0-9_\-]+) died"
			if [[ $line =~ $connectedRegex ]]; then
				echo "connected;${BASH_REMATCH[1]};${BASH_REMATCH[2]}"
			elif [[ $line =~ $disconnectedRegex ]]; then
				echo "disconnected;${BASH_REMATCH[1]};${BASH_REMATCH[2]}"
			elif [[ $line =~ $userDiedRegex ]]; then
				echo "died;${BASH_REMATCH[1]};${BASH_REMATCH[2]}"
			fi
		done < $f
	done
}

processLogs



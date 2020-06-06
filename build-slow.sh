#!/bin/bash

# Directories and Files
LIBDIR=./tools/lib/
LIBAFA=libaudiofile.a
LIBAFLA=libaudiofile.la
AUDDIR=./tools/audiofile-0.3.6
MASTER=./sm64pc-master/
MASTER_GIT=./sm64pc-master/.git/
MASTER_ROM=./sm64pc-master/baserom.us.z64
MASTER_OLD=./sm64pc-master.old/baserom.us.z64
NIGHTLY=./sm64pc-nightly/
NIGHTLY_GIT=./sm64pc-nightly/.git/
NIGHTLY_ROM=./sm64pc-nightly/baserom.us.64
NIGHTLY_OLD=./sm64pc-nightly.old/baserom.us.z64

# Command line options
OPTIONS=("Analog Camera" "No Draw Distance" "Smoke Texture Fix" "Clean build")
EXTRA=("BETTERCAMERA=1" "NODRAWINGDISTANCE=1" "TEXTURE_FIX=1" "clean")

# Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# Gives options to download from the Github
printf "\n${GREEN}Would you like to download the latest source files from Github? (y/n) ${RESET}\n"
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
	printf "\n${GREEN}Would you like to download the master (stable version with new updates)\nor the nightly (newest experimental version)? (master/nightly) ${RESET}\n"
    read answer
	if [ "$answer" != "${answer#[Mm]}" ] ;then
		# Checks for existince of previous .git folder then creates one if it doesn't exist and moves the old folder
		if [ -d "$MASTER_GIT" ]; then
			cd ./sm64pc-master
			printf "\n"
			git stash push
			git stash drop
			git pull https://github.com/sm64pc/sm64pc master
			I_Want_Master=true
			cd ../
		else
			if [ -d "$MASTER" ]; then
				mv sm64pc-master sm64pc-master.old
				printf "\n"
				git clone https://github.com/sm64pc/sm64pc master
				mv master sm64pc-master
				I_Want_Master=true
			else
				printf "\n"
				git clone https://github.com/sm64pc/sm64pc master
				mv master sm64pc-master
				I_Want_Master=true
			fi
		fi
	else
		if [ -d "$NIGHTLY_GIT" ]; then
			cd ./sm64pc-nightly
			printf "\n"
			git stash push
			git stash drop
			git pull https://github.com/sm64pc/sm64pc nightly
			I_Want_Nightly=true
			cd ../
		else
			if [ -d "$NIGHTLY" ]; then
				printf "\n"
				mv sm64pc-nightly sm64pc-nightly.old
				git clone https://github.com/sm64pc/sm64pc nightly
				mv nightly sm64pc-nightly
				I_Want_Nightly=true
			else
				printf "\n"
				git clone https://github.com/sm64pc/sm64pc nightly
				mv nightly sm64pc-nightly
				I_Want_Nightly=true
			fi
		fi
	fi
else
    printf "\n${GREEN}Are you building master or nightly? (master/nightly)"
	read answer
	if [ "$answer" != "${answer#[Mm]}" ] ;then
		cd ./sm64pc-master
	else
		cd ./sm64pc-nightly
	fi
fi

# Checks for baserom in sm64pc-master or sm64pc-nightly
if [ -f "$MASTER_ROM" ]; then
	Base_Rom=true
fi

if [ -f "$NIGHTLY_ROM" ]; then
	Base_Rom=true
fi

# Checks for a pre-existing baserom file in old folder then moves it to the new one
if [ -f "$MASTER_OLD" ]; then
	cd ./sm64pc-master.old
    mv baserom.us.z64 ../sm64pc-master/baserom.us.z64
	cd ../
	Base_Rom=true
fi

if [ -f "$NIGHTLY_OLD" ]; then
	cd ./sm64pc-nightly.old
    mv baserom.us.z64 ../sm64pc-nightly/baserom.us.z64
	cd ../
	Base_Rom=true
fi

if [ "$Base_Rom" = true ] ; then
	printf "\n\n${GREEN}Existing baserom found${RESET}"
else
	if [ "$I_Want_Master" = true ]; then
		printf "\n${YELLOW}Place your baserom.us.z64 file in the ${MASTER} folder${RESET}"
		read -n 1 -r -s -p $'\n\nPRESS ENTER TO CONTINUE...\n'
	fi
	
	if [ "$I_Want_Nightly" = true ]; then
		printf "\n${YELLOW}Place your baserom.us.z64 file in the ${NIGHTLY} folder${RESET}"
		read -n 1 -r -s -p $'\n\nPRESS ENTER TO CONTINUE...\n'
	fi
fi

# Checks for which version the user selected
if [ "$I_Want_Master" = true ]; then
    cd ./sm64pc-master
fi

if [ "$I_Want_Nightly" = true ]; then
    cd ./sm64pc-nightly
fi

# Checks to see if the libaudio directory and files exist
if [ -d "$LIBDIR" -a -e "${LIBDIR}$LIBAFA" -a -e "${LIBDIR}$LIBAFLA"  ]; then
    printf "\n${GREEN}libaudio files exist, going straight to compiling.${RESET}\n"
else 
    printf "\n${GREEN}libaudio files not found, starting initialization process.${RESET}\n\n"

    printf "${YELLOW} Changing directory to: ${CYAN}${AUDDIR}${RESET}\n\n"
		cd $AUDDIR

    printf "${YELLOW} Executing: ${CYAN}autoreconf -i${RESET}\n\n"
		autoreconf -i

    printf "\n${YELLOW} Executing: ${CYAN}./configure --disable-docs${RESET}\n\n"
		PATH=/mingw64/bin:/mingw32/bin:$PATH LIBS=-lstdc++ ./configure --disable-docs

    printf "\n${YELLOW} Executing: ${CYAN}make${RESET}\n\n"
		PATH=/mingw64/bin:/mingw32/bin:$PATH make

    printf "\n${YELLOW} Making new directory ${CYAN}../lib${RESET}\n\n"
		mkdir ../lib


    printf "${YELLOW} Copying libaudio files to ${CYAN}../lib${RESET}\n\n"
		cp libaudiofile/.libs/libaudiofile.a ../lib/
		cp libaudiofile/.libs/libaudiofile.la ../lib/

    printf "${YELLOW} Going up one directory.${RESET}\n\n"
		cd ../
		
		#Checks if the Makefile has already been changed

		sed -i 's/tabledesign_CFLAGS := -Wno-uninitialized -laudiofile/tabledesign_CFLAGS := -Wno-uninitialized -laudiofile -lstdc++/g' Makefile

    printf "${YELLOW} Executing: ${CYAN}make${RESET}\n\n"
		PATH=/mingw64/bin:/mingw32/bin:$PATH make

    printf "\n${YELLOW} Going up one directory.${RESET}\n"
		cd ../
fi 

menu() {
		printf "\nAvaliable options:\n"
		for i in ${!OPTIONS[@]}; do 
				printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${OPTIONS[i]}"
		done
		if [[ "$msg" ]]; then echo "$msg"; fi
		printf "${YELLOW}Please do not select \"Clean build\" with any other option.\n"
		printf "${RED}WARNING: Backup your save file before selecting \"Clean build\".\n"
		printf "${CYAN}Press the corresponding number and press enter to select it.\nWhen all desired options are selected press enter to continue.\n"
		printf "Leave all options unchecked for a Vanilla build.\n${RESET}"
}

prompt="Check an option (again to uncheck, press ENTER):"
while menu && read -rp "$prompt" num && [[ "$num" ]]; do
		[[ "$num" != *[![:digit:]]* ]] &&
		(( num > 0 && num <= ${#OPTIONS[@]} )) ||
		{ msg="Invalid option: $num"; continue; }
		((num--)); # msg="${OPTIONS[num]} was ${choices[num]:+un}checked"
		[[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
done

for i in ${!OPTIONS[@]}; do 
		[[ "${choices[i]}" ]] && { CMDL+=" ${EXTRA[i]}"; }
done 

printf "\n${YELLOW} Executing: ${CYAN}make ${CMDL}${RESET}\n\n"
PATH=/mingw32/bin:/mingw64/bin:$PATH make $CMDL

if [ "${CMDL}" != " clean" ]; then

	printf "\n${GREEN}If all went well you should have a compiled .EXE in the 'build/us_pc/' folder.\n"
	printf "\n${YELLOW}If fullscreen doesn't seem like the correct resolution then right click on the\nexe, go to properties, compatibility then click Change high DPI settings.\nCheckmark Override high DPI scaling behavior, and leave it on application then\napply."
	#printf "${CYAN}Would you like to run the game? [y or n]: ${RESET}"
	#read TEST

	#if [ "${TEST}" = "y" ]; then
	#	exec ./build/us_pc/sm64.us.f3dex2e.exe
	#fi 
else
	printf "\nYour build is now clean\n"
fi 
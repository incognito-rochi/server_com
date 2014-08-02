#!/bin/sh

cyan='\e[1;37;44m'
red='\e[1;31m'
endColor='\e[0m'
datetime=$(date +%Y%m%d%H%M%S)

lowercase(){
	echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

####################################################################
# Get System Info
####################################################################
shootProfile(){
	OS=`lowercase \`uname\``
	KERNEL=`uname -r`
	MACH=`uname -m`

	if [ "${OS}" == "windowsnt" ]; then
		OS=windows
	elif [ "${OS}" == "darwin" ]; then
		OS=mac
	else
		OS=`uname`
		if [ "${OS}" = "SunOS" ] ; then
			OS=Solaris
			ARCH=`uname -p`
			OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
		elif [ "${OS}" = "AIX" ] ; then
			OSSTR="${OS} `oslevel` (`oslevel -r`)"
		elif [ "${OS}" = "Linux" ] ; then
			if [ -f /etc/redhat-release ] ; then
				DistroBasedOn='RedHat'
				DIST=`cat /etc/redhat-release |sed s/\ release.*//`
				PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
				REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
			elif [ -f /etc/SuSE-release ] ; then
				DistroBasedOn='SuSe'
				PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
				REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
			elif [ -f /etc/mandrake-release ] ; then
				DistroBasedOn='Mandrake'
				PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
				REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
			elif [ -f /etc/debian_version ] ; then
				DistroBasedOn='Debian'
				if [ -f /etc/lsb-release ] ; then
			        	DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
			                PSUEDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
			                REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
            			fi
			fi
			if [ -f /etc/UnitedLinux-release ] ; then
				DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
			fi
			OS=`lowercase $OS`
			DistroBasedOn=`lowercase $DistroBasedOn`
		 	readonly OS
		 	readonly DIST
			readonly DistroBasedOn
		 	readonly PSUEDONAME
		 	readonly REV
		 	readonly KERNEL
		 	readonly MACH
		fi

	fi
}
shootProfile
#echo "OS: $OS"
#echo "DIST: $DIST"
#echo "PSUEDONAME: $PSUEDONAME"
#echo "REV: $REV"
#echo "DistroBasedOn: $DistroBasedOn"
#echo "KERNEL: $KERNEL"
#echo "MACH: $MACH"
#echo "========"

####################################################################
# Print Menu
####################################################################
printMenu(){
	if [[ "$user" = "" || "$passwd" = "" || "$port" = "" ]]; then
		echo -e "$red Error: USER, PASS AND PORT ARE REQUIRED, PLEASE SET THEM IN CONFIG FILE $endColor"
		echo ""
		echo ""
		exit 1 
	fi
	clear
	echo -e "$cyan Fast and Easy Web Server Installation $endColor"
	echo "Choose an option writing its number and press enter:"
	echo -e "\t11) Create a user"
	echo -e "\t12) Create users profile(color in bash)"
	echo -e "\t13) Update and Install(Apache,PHP,MySQL,SQLite,Django,Subversion,git)"
	echo -e "\t14) Configurating SSH and IPTABLES"
	echo -e "\t15) Configure and securitizing Apache"
	echo -e "\t16) Configure and securitizing MySQL"
	echo -e "\t17) Create SVN & TRAC repos"
	echo -e "\t18) Create a Mail Server(postfix)"
	echo -e "\t19) Create a Mail Server(postfix,dovecot,roundcube)"
	echo -e "\t20) Create a cron backup (mysql, apache, trac & svn)"
	echo -e "\t21) Set DNS and to add Google Apps MX records (Only SliceHost.com)"
	echo -e "\t22) Install Trac and its Plugins"
	echo -e "\t23) Configure and securitizing Samba"
	echo -e "\t24) Create VirtualHosts"
	echo -e "\t25) I do not know, exit!"
	read option;
	while [[ $option -gt 25 || ! $(echo $option | grep '^[1-9][0-9]') ]]
	do
		printMenu
	done
	runOption
}

####################################################################
# Run an Option
####################################################################
runOption(){
	case $option in
		11) createUser;;
		12) profileUser;;
		13) updateInstall;;
		14) sshIptables;;
		15) secureApache;;
		16) secureMySQL;;
		17) tracsvn;;
		18) mailServer;;
		19) mailServer_com;;
		20) cronBackup;;
		21) set_dns;;
		22) InstallTrac;;
		23) InstallSamba;;
		24) CreateVirtualHosts;;
		25) exit;;
	esac 
	echo "Press any Key to continue"
	read x
	printMenu
}



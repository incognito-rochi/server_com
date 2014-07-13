####################################################################
# Vars
####################################################################
echo "redhat functions were loaded"
apache_conf='/etc/httpd/conf/httpd.conf'
apache_user='apache'
ssh_service='/etc/init.d/sshd'
mysql_service='mysqld'
apache_service='/etc/init.d/httpd'


if [ "${DIST}" = "CentOS" ] ; then
	# Recommended to CENTOS 
	userProfile='export PS1="\[\e[0;36m\]\u\[\e[1;35m\]@\H \[\033[0;36m\] \w\[\e[0m\]$ "'
	rootProfile='export PS1="\[\e[1;31m\]\u\[\e[1;35m\]@\H \[\033[0;36m\] \w\[\e[0m\]$ "'
else
	# Recommended to REDHAT
	userProfile='export PS1="\[\e[0;36m\]\u\[\e[1;31m\]@\H \[\033[0;36m\] \w\[\e[0m\]$ "'
	rootProfile='export PS1="\[\e[1;31m\]\u\[\e[1;31m\]@\H \[\033[0;36m\] \w\[\e[0m\]$ "'
fi

####################################################################
# Create USER
####################################################################
createUser(){
	if [ ! `whoami` = "root" ]; then 
		echo -e "$red Error: You must to be ROOT user to run this function $endColor"
		return
	fi
	echo -e "$cyan============================ Creating a user $user... =============================$endColor"

	test_user=`id -u $user`;

	if [ "$test_user" = "550" ]; then 
		echo -e "$cyan##### REMOVING PREVIUOS USER ENTRY #####$endColor"
		userdel -r $user
	fi

	echo -e "$cyan##### Add user $user #####$endColor"
	adduser $user -d /home/$user -u 550 -G wheel
	echo "$passwd" | passwd --stdin $user

	echo -e "$cyan##### Add wheel group to sudo #####$endColor"
	sed '/^#.*%wheel\tALL=(ALL)\tALL.*/ s/^#//' /etc/sudoers > tmp
	cat tmp > /etc/sudoers
	echo -e "$cyan==================== User $user created successfully ====================$endColor"
}

####################################################################
# Profile USER
####################################################################
profileUser(){
	echo $userProfile > tmp
	cat tmp >> /home/$user/.bash_profile
	source /home/$user/.bash_profile
	echo -e "$cyan==================== Bash Profile to User $user created ====================$endColor"
	echo $rootProfile > tmp
	cat tmp >> /root/.bash_profile
	source /root/.bash_profile
	echo -e "$cyan==================== Bash Profile to User root created ====================$endColor"
}

####################################################################
# Update and Install Apache, PHP, MySQL, Django, Subversion, TRAC
####################################################################
updateInstall(){
	echo -e "$cyan======= Updating and Installing Apache, PHP, MySQL, Django, Subversion ======$endColor"

	echo -e "$cyan##### Updating Operating System... #####$endColor" 
	yum clean all
	yum -y update
	echo -e "$cyan================ System Updated successfully ================$endColor"

	yum -y install httpd mod_ssl 
	yum -y install mysql mysql-server 
	yum -y install php php-cli php-common php-mysql php-mcrypt php-mhash php-mbstring php-gd
	yum -y install python-setuptools MySQL-python mod_python Django
	yum -y install subversion mod_dav_svn
	yum -y install git
	
	# Install Django 1.1.1
	# wget http://www.djangoproject.com/download/1.1.1/tarball/
	# tar -xzf Django-1.1.1.tar.gz
	# rm -f Django-1.1.1.tar.gz
	# cd Django-1.1.1

	# Required to VirtualBox
	# yum -y install gcc kernel-devel
	# /etc/init.d/vboxdrv setup
	# yum -y remove gcc kernel-devel

	echo -e "$cyan================ Packages Installed successfully ================$endColor"
}

####################################################################
# Install TRAC
####################################################################
InstallTrac(){
	echo -e "$cyan##### Trac Install #####$endColor"  
	sudo easy_install Trac

	echo -e "$cyan##### Trac Plugins Install #####$endColor" 
	easy_install TracAccountManager TracProjectMenu
	echo -e "$cyan================ Trac Installed successfully ================$endColor"
}

####################################################################
# Install SAMBA
####################################################################
InstallSamba(){
	echo -e "$cyan##### Samba Install #####$endColor"  
	yum -y install samba samba-client samba-common
	
	mkdir -p /etc/samba/ccd             
	chmod -R 0777 /etc/samba/ccd/
	
	if [ ! -f /etc/samba/smb.conf.orig ]; then
		cp /etc/samba/smb.conf /etc/samba/smb.conf.orig
	fi
	
	rm -rf /etc/samba/smb.conf
	
cat <<'EOF' > /etc/samba/smb.conf
[global]
unix charset = UTF-8
dos charset = CP932
workgroup = DOCS 
netbios name = DOCS_SRV 
security = share 
printcap name = cups 
disable spools= Yes 
show add printer wizard = No 
printing = cups  

[printers] 
comment = All Printers 
path = /var/spool/samba 
guest ok = Yes 
printable = Yes 
use client driver = Yes 
browseable = Yes

	hosts allow = 127. 192.168.12. 192.168.13. 192.168.0.
	
	
	# Max Log Size let you specify the max size log files should reach
	
	# logs split per machine
	log file = /var/log/samba/log.%m
	# max 50KB per log file, then rotate
	max log size = 50
	
	
	# A publicly accessible directory, but read only, except for people in
	# the "staff" group
	[office]
	comment = Public Stuff
	path = /etc/samba/ccd/
	browsable = yes
	writable = yes
	guest ok = no
	create mode = 0775
	directory mode = 0775

EOF


	rpm -qa | grep samba
	chkconfig smb on
	chkconfig smb --list
	chkconfig nmb on
	chkconfig nmb --list
	
	
	service smb restart
	service nmb restart

	#test samba configuration
	testparm       

#########firewall & iptables#########

	iptables -I INPUT -p tcp -m tcp --dport 137 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 138 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 139 -j ACCEPT
	iptables -I INPUT -p tcp -m tcp --dport 445 -j ACCEPT
	service iptables save
	service iptables restart
}

####################################################################
# Create VirtualHosts
####################################################################
CreateVirtualHosts(){
	echo -e "$cyan============================= Creating VirtualHosts ================================$endColor"
	
	echo -e "$cyan#####    Reset Folders @ Apache  #####$endColor"
	rm -rf /var/www/svn /var/www/trac /var/www/html /var/www/logs
	rm -rf /etc/httpd/conf.d/0*
	mkdir -p /var/www/svn /var/www/trac /var/www/html /var/www/logs



	echo -e "$cyan=============================== Folders permission ==================================$endColor"
	chown -R apache:apache /var/www/trac/ /var/www/svn/ /var/www/html/ /var/www/logs/ /var/www/phpmyadmin/
	chmod -R 755 /var/www/trac/ /var/www/svn/ /var/www/html/ /var/www/logs/ /var/www/phpmyadmin/

	echo -e "$cyan=============================== HTTPD Restart ==================================$endColor"
	sudo /etc/init.d/httpd start 
}

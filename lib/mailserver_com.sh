####################################################################
# Install properly everything to send emails
# Author: Raisul Islam
# URL: http://rochi.netii.net
# Created: July 02, 2014
####################################################################
# to see log file
# cat /var/log/maillog
mailServer_com(){
	if [ "$nameSlice" = "" ]; then
		echo -e "$red Error: You must to set a nameSlice on config file $endColor"
		return 
	fi

	####################################################################
	# Host Configuration
	####################################################################

	echo -e "$cyan##### HOSTNAME will be same to Slice Name ($nameSlice) #####$endColor"

	echo "
	NETWORKING=yes
	HOSTNAME=$nameSlice
	GATEWAY=$gateway
	" > /etc/sysconfig/network

	echo -e "
	127.0.0.1 	localhost localhost.localdomain
	$ipServer 	$nameSlice
	" > /etc/hosts
	# test it with : hostname -f
	
	####################################################################
	# Reseting postfix
	####################################################################

	yum remove -y postfix
	rm -rf /etc/postfix/
	
	####################################################################
	# Reseting Dovecot
	####################################################################

	yum remove -y dovecot
	rm -rf /etc/dovecot/

	####################################################################
	# Installing postfix and dovecot
	####################################################################

	yum install -y postfix
	yum install -y dovecot dovecot-mysql

	####################################################################
	# Adding iptables rules for postfix
	####################################################################

	sudo /sbin/iptables -I INPUT -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
	sudo /sbin/iptables -I OUTPUT -p tcp --sport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
	sudo /sbin/iptables -I INPUT -p tcp --dport 143 -m state --state NEW,ESTABLISHED -j ACCEPT
	sudo /sbin/iptables -I OUTPUT -p tcp --sport 143 -m state --state NEW,ESTABLISHED -j ACCEPT
	sudo service iptables save

	####################################################################
	# Starting postfix at boot time
	####################################################################

	sudo /sbin/chkconfig --add postfix
	sudo /sbin/chkconfig --add dovecot
	sudo /sbin/chkconfig postfix on
	sudo /sbin/chkconfig dovecot on

	####################################################################
	# Postfix Configuration
	####################################################################

	if [ ! -f /etc/postfix/main.cf.orig ]; then
		cp /etc/postfix/main.cf /etc/postfix/main.cf.orig
	fi

	sed '/^#alias_maps = hash:\/etc\/aliases$/ s/^#//' /etc/postfix/main.cf > tmp
	cat tmp > /etc/postfix/main.cf
	sed '/^#alias_database = hash:\/etc\/aliases$/ s/^#//' /etc/postfix/main.cf > tmp
	cat tmp > /etc/postfix/main.cf
	sed "/^#mydomain = domain.tld/ s/^#mydomain = domain.tld/mydomain = $mydomain/" /etc/postfix/main.cf > tmp
	cat tmp > /etc/postfix/main.cf
	sed '/^#myorigin = \$mydomain.*/ s/^#//' /etc/postfix/main.cf > tmp
	cat tmp > /etc/postfix/main.cf
	sed '/^#mynetworks = 168.100.189.0\/28, 127.0.0.0\/8.*/ s/^#//' /etc/postfix/main.cf > tmp
	cat tmp > /etc/postfix/main.cf
	sed '/^mynetworks = 168.100.189.0\/28, 127.0.0.0\/8.*/ s/168.100.189.0\/28, //' /etc/postfix/main.cf > tmp
	cat tmp > /etc/postfix/main.cf
	sed '/^#inet_interfaces = all/ s/^#inet_interfaces = all/inet_interfaces = localhost/' /etc/postfix/main.cf > tmp
	cat tmp > /etc/postfix/main.cf
	sed '/^#home_mailbox = Maildir\/$/ s/^#//' /etc/postfix/main.cf > tmp
	cat tmp > /etc/postfix/main.cf
	echo -e "$cyan##### Postfix Configurated #####$endColor"

	sudo /etc/init.d/postfix start

	####################################################################
	# Aliases Configuration
	####################################################################

	if [ ! -f /etc/aliases.orig ]; then
		cp /etc/aliases /etc/aliases.orig
	fi
	sed '/^#root:.*marc$/ s/^#//' /etc/aliases > tmp
	cat tmp > /etc/aliases
	sed "/^root:.*marc$/ s/marc$/$mailAdmin/" /etc/aliases > tmp
	cat tmp > /etc/aliases

	sudo /usr/bin/newaliases
	echo -e "$cyan##### Aliases Added #####$endColor"
	echo -e "$cyan=============== Mailserver created successfully ===============$endColor"
	
	####################################################################
	# Dovecot Configuration
	####################################################################
	
	if [ ! -f /etc/dovecot/dovecot.conf.orig ]; then
		cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig
	fi
	
	echo -e "$cyan##### Dovecot Configurated #####$endColor"

	sudo /etc/init.d/dovecot start

}

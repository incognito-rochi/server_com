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
	yum install -y dovecot dovecot-mysql dovecot-pigeonhole opendkim

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
	chkconfig opendkim on
	

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
	
	rm -rf /etc/dovecot/dovecot.conf
	cp -R $base_path/lib/conf-files/dovecot.conf /etc/dovecot/
	read -e -p "Enter the FQDN of the server (example: yourdomain.com): " -i $fqdn fqdn
	sed -i "s|postmaster_address = postmaster@your-domain.tld|postmaster_address = postmaster@$fqdn|" /etc/dovecot/dovecot.conf
	
	
	echo -e "$cyan##### Dovecot Configurated #####$endColor"
	echo -e "$cyan========= POP3 and IMEP conf created successfully ===========$endColor"

	sudo /etc/init.d/dovecot start
	
	####################################################################
	# RoundCube Installation
	####################################################################
	
	updateInstall()
	
	echo -e "$cyan##### RoundCube Installation Started #####$endColor"
	cd $basepath/lib/downloads/
	
	wget -P /var/www/html http://sourceforge.net/projects/roundcubemail/files/roundcubemail/0.8.5/roundcubemail-0.8.5.tar.gz/download#
	tar -C /var/www/html -zxvf /var/www/html/roundcubemail-*.tar.gz
	rm -f /var/www/html/roundcubemail-*.tar.gz 
	mv /var/www/html/roundcubemail-* /var/www/html/roundcube 
	chown root:root -R /var/www/html/roundcube
	chown -R apache:apache /var/www/html/roundcubemail
	chmod 777 -R /var/www/html/roundcube/temp/ 
	chmod 777 -R /var/www/html/roundcube/logs/

#cat <<EOF  /etc/httpd/conf.d/20-roundcube.conf
#Alias /webmail /var/www/html/roundcube

#<Directory /var/www/html/roundcube>
#Options -Indexes
#AllowOverride All
#</Directory>

#<Directory /var/www/html/roundcube/config>
#Order Deny,Allow
#Deny from All
#</Directory>

#<Directory /var/www/html/roundcube/temp>
#Order Deny,Allow
#Deny from All
#</Directory>

#<Directory /var/www/html/roundcube/logs>
#Order Deny,Allow
#Deny from All
#</Directory>
#EOF
	
#sed -e "s|mypassword|${mysql_roundcube_password}|" <<EOF | mysql -u root -p$passwd
#USE mysql;
#CREATE USER 'roundcube'@'localhost' IDENTIFIED BY 'mypassword';
#GRANT USAGE ON * . * TO 'roundcube'@'localhost' IDENTIFIED BY 'mypassword';
#CREATE DATABASE IF NOT EXISTS `roundcube`;
#GRANT ALL PRIVILEGES ON `roundcube` . * TO 'roundcube'@'localhost';
#FLUSH PRIVILEGES;
#EOF

#	mysql -u root -p$passwd roundcube < /var/www/html/roundcube/SQL/mysql.initial.sql

	cp /var/www/html/roundcube/config/main.inc.php.dist /var/www/html/roundcube/config/main.inc.php

	sed -i "s|^\(\$rcmail_config\['default_host'\] =\).*$|\1 \'localhost\';|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['smtp_server'\] =\).*$|\1 \'localhost\';|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['smtp_user'\] =\).*$|\1 \'%u\';|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['smtp_pass'\] =\).*$|\1 \'%p\';|" /var/www/html/roundcube/config/main.inc.php
	#sed -i "s|^\(\$rcmail_config\['support_url'\] =\).*$|\1 \'mailto:${E}\';|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['quota_zero_as_unlimited'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['preview_pane'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['read_when_deleted'\] =\).*$|\1 false;|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['check_all_folders'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['display_next'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['top_posting'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['sig_above'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php
	sed -i "s|^\(\$rcmail_config\['login_lc'\] =\).*$|\1 2;|" /var/www/html/roundcube/config/main.inc.php

	cp /var/www/html/roundcube/config/db.inc.php.dist /var/www/html/roundcube/config/db.inc.php

	sed -i "s|^\(\$rcmail_config\['db_dsnw'\] =\).*$|\1 \'mysqli://roundcube:${mysql_roundcube_password}@localhost/roundcube\';|" /var/www/html/roundcube/config/db.inc.php

	rm -rf /var/www/html/roundcube/installer

	echo -e "$cyan##### RoundCube Installation has completed successfully #####$endColor"

	echo -e "$cyan##### HTTP Server Reloading #####$endColor"
	service httpd reload
	echo -e "$cyan##### HTTP Server Reloaded #####$endColor"
	
	
	echo -e "$cyan========= Mail Server Installed successfully ===========$endColor"
	
}

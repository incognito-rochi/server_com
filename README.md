server_com
==========
 
- Edited By   : Raisul Islam
- Last Updated: August 02th, 2014

## Description
Install easily a secure web server on linux. You can choose what you want to install between a lot of packages.

**Server Com** is a Bash Script project that help you to install and configure a Cross-Linux server with insteresting packages and funtionalities, like Wordpress, MySQL, TRAC, and many more.

### List of packages availables to install and configure:

 * TRAC
 * SVN
 * Iptables (Most secure)
 * SSH (Change port by default and securitize)
 * Apache
 * Django (Web Framework of awesome Python)
 * MySQL
 * Cron Backup of databases, websites, etc
 * Mail Server
 * Samba
 * Virtualhost

### Tested
**Server Com** was tested on next Linux Operating System
 
 * CentOS
 * Red Hat Enterprise Linux 
 * Ubuntu 12.04.3 x64
 * It is not tested but should work in Mandrake, Debian, Fedora

## Installation

 1. Download the project and extract the project

 ```sh
 git clone https://github.com/incognito-rochi/server_com.git
 ```

 2. Create a config file and run the Bash

 ```
 cd server_com/
 cp config.sample config
 bash install.sh
 ```

 	

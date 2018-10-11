#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

#Update packages and Upgrade system
echo "Updating System"
sudo yum -y update && sudo yum -y upgrade

echo "Installing Apache2"
sudo yum -y install httpd

#Finding Public IP of Server
PUB_IP="$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')"

#Editing apache2.conf file
echo "ServerName $PUB_IP" >> /etc/apache2/apache2.conf

#Installing PHP and required modules
echo "Installing php modules"
echo "deb http://ftp.de.debian.org/debian stretch main" >> /etc/apt/sources.list
yum -y install php7.0-fpm php7.0-cli php7.0-common libapache2-mod-php7.0 php7.0-mcrypt php7.0-mysql php5-mysqlnd

#Setting permissions and ownership for /var/www
echo "Setting ownership on /var/www"
sudo chown -R www-data:www-data /var/www
find /var/www/html/ -type f -exec chmod 664 {} \;
find /var/www/html/ -type d -exec chmod 775 {} \;

#Downloading demo.php file
wget https://<AZURE_STORAGE_ACCOUNT_NAME>.blob.core.windows.net/<CONTAINER_NAME>/demo.php -O /var/www/html/demo.php
sudo chown -R www-data:www-data /var/www/html/demo.php

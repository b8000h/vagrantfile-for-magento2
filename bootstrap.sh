#!/usr/bin/env bash

SAMPLE_DATA=$1

# Git for modman and Vundle
apt-get -q -y install git


# Update Apt
# --------------------
apt-get update

# Git for modman and Vundle
apt-get -q -y install git

apt-get -q -y install composer


# Install Apache & PHP
# --------------------
apt-get install -y apache2
apt-get install -y php5
apt-get install -y libapache2-mod-php5
# required: php5-intl php5-mcrypt php5-imagck php5-xsl
apt-get install -y php5-mysqlnd php5-curl php5-xdebug php5-gd php5-intl php-pear php5-imap php5-mcrypt php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-soap
php5enmod mcrypt
# release some limit in php.ini
# --------------------
sed -e 's/max_execution_time = 60/max_execution_time = 300/' -i /etc/php5/apache2/php.ini
sed -e 's/memory_limit = 32M/memory_limit = 2G/' -i /etc/php5/apache2/php.ini
sed -e 's/post_max_size = 8M/post_max_size = 64M/' -i /etc/php5/apache2/php.ini
sed -e 's/upload_max_filesize = 8M/upload_max_filesize = 64M/' -i /etc/php5/apache2/php.ini

# Delete default apache web dir and symlink mounted vagrant dir from host machine
# --------------------
rm -rf /var/www/html
mkdir /vagrant/httpdocs
ln -fs /vagrant/httpdocs /var/www/html
# Replace contents of default Apache vhost
# --------------------
VHOST=$(cat <<EOF
NameVirtualHost *:8080
Listen 8080
<VirtualHost *:80>
  DocumentRoot "/var/www/html"
  ServerName localhost
  <Directory "/var/www/html">
    AllowOverride All
  </Directory>
</VirtualHost>
<VirtualHost *:8080>
  DocumentRoot "/var/www/html"
  ServerName localhost
  <Directory "/var/www/html">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)
echo "$VHOST" > /etc/apache2/sites-enabled/000-default.conf
a2enmod rewrite
service apache2 restart


# Mysql
# --------------------
# Ignore the post install questions
export DEBIAN_FRONTEND=noninteractive
# Install MySQL quietly
apt-get -q -y install mysql-server-5.6
mysql -u root -e "CREATE DATABASE IF NOT EXISTS magentodb"
mysql -u root -e "GRANT ALL PRIVILEGES ON magentodb.* TO 'magentouser'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -e "FLUSH PRIVILEGES"


apt-get -q -y install zip


cd /vagrant/httpdocs
composer create-project --repository-url=https://repo.magento.com/  magento/project-community-edition .
# 
# Publick Key 是 Username，0788301c2980dc83b2ffb66b335b8ff0，AutoHotKey 热键设为 @m2username 
# Private Key 是 Password，a765d078c24939cd3a0851b4f55dbb46，AutoHotKey 热键设为 @m2password 
# 写入
/vagrant/.composer/auth.json

# Run installer
if [ ! -f "/vagrant/httpdocs/app/etc/local.xml" ]; then
  cd /vagrant/httpdocs
  sudo /usr/bin/php -f install.php -- --license_agreement_accepted yes \
  --locale en_US --timezone "America/Los_Angeles" --default_currency USD \
  --db_host localhost --db_name magentodb --db_user magentouser --db_pass password \
  --url "http://127.0.0.1:8080/" --use_rewrites yes \
  --use_secure no --secure_base_url "http://127.0.0.1:8080/" --use_secure_admin no \
  --skip_url_validation yes \
  --admin_lastname Owner --admin_firstname Store --admin_email "admin@example.com" \
  --admin_username admin --admin_password password123123
  /usr/bin/php -f shell/indexer.php reindexall
fi

php /var/www/html/magento2/bin/magento setup:install --base-url=http://192.0.2.5/magento2/ \
--db-host=localhost --db-name=magento --db-user=mag --db-password=CarlInXGD2015 \
--admin-firstname=Magento --admin-lastname=User --admin-email=810455959@qq.com \
--admin-user=Carl --admin-password=CarlInXGD2015 --language=en_US \
--currency=USD --timezone=America/Chicago --use-rewrites=1



# Install n98-magerun
# --------------------
cd ~
wget https://raw.github.com/netz98/n98-magerun/master/n98-magerun.phar
chmod +x ./n98-magerun.phar
sudo mv ./n98-magerun.phar /usr/local/bin/
sudo ln -s /usr/local/bin/n98-magerun.phar /usr/local/bin/mr
cd /vagrant/httpdocs
n98-magerun.phar cache:disable
# for modman, which require 
n98-magerun.phar dev:symlinks --on --global
n98-magerun.phar dev:module:disable Mage_Authorizenet
n98-magerun.phar dev:module:disable Mage_Bundle
n98-magerun.phar dev:module:disable Mage_Centinel
n98-magerun.phar dev:module:disable Mage_Connect
n98-magerun.phar dev:module:disable Mage_Weee
n98-magerun.phar dev:module:disable Phoenix_Moneybookers

:<<EOF
cd /vagrant/httpdocs/app/etc/modules
sed -e '49,0s/true/false/' -i Mage_All.xml
sed -e '77,0s/true/false/' -i Mage_All.xml
sed -e '186,0s/true/false/' -i Mage_All.xml
#sed -e '194,0s/true/false/' -i Mage_All.xml
sed -e '210,0s/true/false/' -i Mage_All.xml
sed -e '220,0s/true/false/' -i Mage_All.xml
sed -e '340,0s/true/false/' -i Mage_All.xml
sed -e '375,0s/true/false/' -i Mage_All.xml
EOF

# Install modman
# --------------------
cd ~
bash < <(wget -q --no-check-certificate -O - https://raw.github.com/colinmollenhour/modman/master/modman-installer)
sudo mv ~/bin/modman /usr/local/bin/
sudo ln -s /usr/local/bin/modman /usr/local/bin/mm
cd /vagrant/httpdocs
modman init
modman clone https://github.com/dweeves/magmi-git.git
modman clone https://github.com/b8000h/magento-chinese-pack.git
#modman clone https://github.com/b8000h/nullor-hello.git
#modman clone https://github.com/b8000h/auto-currency-switcher.git

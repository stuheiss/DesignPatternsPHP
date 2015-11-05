#!/usr/bin/env bash

uname -a|grep Darwin > /dev/null && { echo "$0: do not run this on your mac!"; exit 1; }
test 0 = `id -u` || { echo "$0: must run as root"; exit 1; }
test -d /vagrant || { echo "$0: missing dir /vagrant"; exit 1; }
cd /vagrant || exit 1

# install ius-release, enable ius-archive
test -f /etc/yum.repos.d/ius.repo || {
	curl -s -o /tmp/install-ius-release.sh https://setup.ius.io
	sh /tmp/install-ius-release.sh
	grep 'enabled=1' /etc/yum.repos.d/ius-archive.repo > /dev/null || sed -i -e '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/ius-archive.repo
}
# install php56, init date.timezone
rpm -q php56u > /dev/null || yum -y install php56u php56u-cli php56u-intl php56u-mcrypt php56u-mysql php56u-curl php56u-json php56u-mbstring
grep '^date\.timezone' /etc/php.ini > /dev/null || {
	sed -i -e "/^;date\.timezone =$/a\date.timezone = 'America/Chicago'" /etc/php.ini
}
# install composer
test -f /usr/bin/composer || {
	curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/bin
}
# install tools
for tool in git unzip wget rcs
do
	rpm -q $tool >/dev/null || yum -y install $tool
done
# install xdebug for coverage
rpm -q php56u-pecl-xdebug >/dev/null || yum -y php56u-pecl-xdebug

echo "append to codeception.yml for coverage:
coverage:
    include:
        - Behavioral/*
        - Creational/*
        - More/*
        - Structural/*
    exclude:
        - Behavioral/*/Tests/*
        - Creational/*/Tests/*
        - More/*/Tests/*
        - Structural/*/Tests/*
"

# install mysql
yum -y install mysql-server

# disable fw
/sbin/iptables -F

# start mysqld
/sbin/chkconfig mysqld || /sbin/chkconfig mysqld on
/sbin/service mysqld status >/dev/null || /sbin/service mysqld start

echo "now try: vendor/bin/phpunit"
echo "now try: vendor/bin/codecept run unit"
echo "now try: vendor/bin/codecept run unit --coverage-html"

echo "done!"


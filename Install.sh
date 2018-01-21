#!/bin/bash

# Go to root
cd

#ca-certificates
apt-get install ca-certificates

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
MYPORT="s/85/99/g";

#FIGlet In Linux
sudo apt-get install figlet
yum install figlet

# update apt-file
apt-file update


# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install wget and curl
apt-get update;apt-get -y install wget curl;

# Set Location GMT +7
ln -fs /usr/share/zoneinfo/Asia/Bangkok /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# set repo
wget -O /etc/apt/sources.list "https://raw.githubusercontent.com/oi10536/SSH-OpenVPN/master/API/sources.list.debian7"
wget "https://raw.githubusercontent.com/oi10536/SSH-OpenVPN/master/API/dotdeb.gpg"
wget "https://raw.githubusercontent.com/oi10536/SSH-OpenVPN/master/API/jcameron-key.asc"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg
cat jcameron-key.asc | apt-key add -;rm jcameron-key.asc

# Update
apt-get update

# install webserver
apt-get -y install nginx

# install essential package
apt-get -y install nano iptables dnsutils openvpn screen whois ngrep unzip unrar

# Install Screenfetch
cd
wget -O /usr/bin/screenfetch "https://raw.githubusercontent.com/nwqionnwkn/OPENEXTRA/master/Config/screenfetch"
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile

# install webserver
cd
apt-get -y install nginx php5 php5-fpm php5-cli php5-mysql php5-mcrypt
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/oi10536/SSH-OpenVPN/master/API/nginx.conf"
mkdir -p /home/vps/public_html
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/oi10536/SSH-OpenVPN/master/API/vps.conf"
sed -i 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
sed -i $MYPORT /etc/nginx/conf.d/vps.conf;
useradd -m vps && mkdir -p /home/vps/public_html
rm /home/vps/public_html/index.html && echo "<?php phpinfo() ?>" > /home/vps/public_html/info.php
chown -R www-data:www-data /home/vps/public_html && chmod -R g+rw /home/vps/public_html
service php5-fpm restart && service nginx restart

# Install Vnstat
apt-get -y install vnstat
vnstat -u -i eth0

# Install OpenVPN
wget -O /etc/openvpn/openvpn.tar "https://github.com/nwqionnwkn/OPENEXTRA/raw/master/Config/openvpn.tar"
cd /etc/openvpn/
tar xf openvpn.tar
cat > /etc/openvpn/1194.conf <<END
port 1194
proto tcp
dev tun

ca /etc/openvpn/keys/ca.crt
dh /etc/openvpn/keys/dh1024.pem
cert /etc/openvpn/keys/server.crt
key /etc/openvpn/keys/server.key

plugin /usr/lib/openvpn/openvpn-auth-pam.so /etc/pam.d/login
client-cert-not-required
username-as-common-name

server 192.168.100.0  255.255.255.0
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

cipher none
comp-lzo

keepalive 5 30

persist-key
persist-tun
client-to-client
status log.log
verb 3
mute 10
END
service openvpn restart
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables-save > /etc/iptables_new.conf
cat > /etc/network/if-up.d/iptables <<END
#!/bin/sh
iptables-restore < /etc/iptables_new.conf
END
chmod +x /etc/network/if-up.d/iptables
service openvpn restart

# Setting Port SSH
cd
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
service ssh restart

# Install Dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 443 -p 80"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/ssh restart
/etc/init.d/dropbear restart

# Install Squid3
cd
apt-get -y install squid3
cat > /etc/squid3/squid.conf <<END
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst xxxxxxxxx-xxxxxxxxx/255.255.255.255
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost
http_access deny all
http_port 8080
coredump_dir /var/spool/squid3
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname openextra.net
END
sed -i $MYIP2 /etc/squid3/squid.conf;

# install webmin
cd
apt-get update
apt-get upgrade
deb http://download.webmin.com/download/repository sarge contrib
deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib
sudo wget http://www.webmin.com/jcameron-key.asc
sudo apt-key add jcameron-key.asc
apt-get update
apt-get install webmin -y

# Install Script
echo -e "\033[1;35m"
# Download Script
cd
sed -i '$ i\screen -AmdS limit /root/limit.sh' /etc/rc.local
sed -i '$ i\screen -AmdS ban /root/ban.sh' /etc/rc.local
sed -i '$ i\screen -AmdS limit /root/limit.sh' /etc/rc.d/rc.local
sed -i '$ i\screen -AmdS ban /root/ban.sh' /etc/rc.d/rc.local
echo "0 0 * * * root /usr/local/bin/user-expire" > /etc/cron.d/user-expire
echo "0 0 * * * root /usr/local/bin/user-expire-pptp" > /etc/cron.d/user-expire-pptp

cat > /root/ban.sh <<END3
#!/bin/bash
#/usr/local/bin/user-ban
END3

cat > /root/limit.sh <<END3
#!/bin/bash
#/usr/local/bin/user-limit
END3

cd /usr/local/bin
wget -O premium-script.tar.gz "https://github.com/lnwshop/vips/blob/master/premium-script.tar.gz"
tar -xvf premium-script.tar.gz
rm -f premium-script.tar.gz

cp /usr/local/bin/premium-script /usr/local/bin/menu

chmod +x /usr/local/bin/trial
chmod +x /usr/local/bin/user-add
chmod +x /usr/local/bin/user-aktif
chmod +x /usr/local/bin/user-ban
chmod +x /usr/local/bin/user-delete
chmod +x /usr/local/bin/user-detail
chmod +x /usr/local/bin/user-expire
chmod +x /usr/local/bin/user-limit
chmod +x /usr/local/bin/user-lock
chmod +x /usr/local/bin/user-login
chmod +x /usr/local/bin/user-unban
chmod +x /usr/local/bin/user-unlock
chmod +x /usr/local/bin/user-password
chmod +x /usr/local/bin/user-log
chmod +x /usr/local/bin/user-add-pptp
chmod +x /usr/local/bin/user-delete-pptp
chmod +x /usr/local/bin/alluser-pptp
chmod +x /usr/local/bin/user-login-pptp
chmod +x /usr/local/bin/user-expire-pptp
chmod +x /usr/local/bin/user-detail-pptp
chmod +x /usr/local/bin/bench-network
chmod +x /usr/local/bin/speedtest
chmod +x /usr/local/bin/ram
chmod +x /usr/local/bin/log-limit
chmod +x /usr/local/bin/log-ban
chmod +x /usr/local/bin/user-generate
chmod +x /usr/local/bin/user-list
chmod +x /usr/local/bin/diagnosa
chmod +x /usr/local/bin/premium-script
chmod +x /usr/local/bin/user-delete-expired
chmod +x /usr/local/bin/auto-reboot
chmod +x /usr/local/bin/log-install
chmod +x /usr/local/bin/menu
chmod +x /usr/local/bin/user-auto-limit
chmod +x /usr/local/bin/user-auto-limit-script
chmod +x /usr/local/bin/edit-port
chmod +x /usr/local/bin/edit-port-squid
chmod +x /usr/local/bin/edit-port-openvpn
chmod +x /usr/local/bin/edit-port-openssh
chmod +x /usr/local/bin/edit-port-dropbear
chmod +x /usr/local/bin/autokill
chmod +x /root/limit.sh
chmod +x /root/ban.sh
screen -AmdS limit /root/limit.sh
screen -AmdS ban /root/ban.sh
clear
cd
echo "สคริปต์พรีเมี่ยมได้รับการอัพเกรดเรียบร้อยแล้ว!"

echo "30 3 * * * root /sbin/reboot" > /etc/cron.d/reboot

echo -e "\033[1;36m "
# finishing

echo ""
echo "..... Installing 98% ...restarting service."

# finishing
cd
chown -R www-data:www-data /home/vps/public_html
service nginx start
service openvpn restart
service cron restart
service ssh restart
service dropbear restart
service squid3 restart
service webmin restart
rm -rf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

# install myweb
cd /home/vps/public_html/
wget -O /home/vps/public_html/myweb.tar "https://raw.githubusercontent.com/oi10536/SSH-OpenVPN/master/API/myweb.tar"
cd /home/vps/public_html/
tar xf myweb.tar

# Setting web
echo -e "\033[01;31mIP User And Pass 'ROOT' Only \033[0m"
read -p "IP : " MyIPD
read -p "Username : " Login
read -p "Password : " Passwd
MYIPS="s/xxxxxxxxx/$MyIPD/g";
US1="s/thaivpnuser/$Login/g";
PS2="s/thaivpnpass/$Passwd/g";
sed -i $MYIPS /home/vps/public_html/index.php;
sed -i $US1 /home/vps/public_html/index.php;
sed -i $PS2 /home/vps/public_html/index.php;

#RM file
rm -f myweb.tar
cd
rm -f Install.sh

# info
clear
echo "====================================================="
echo ""
echo " - OpenVPN  : TCP Port 1194"
echo " - OpenSSH  : Port 22, 143"
echo " - Dropbear : Port 80, 443"
echo " - Squid3   : Port 8080"
echo ""
echo "====================================================="
echo "หลังจากติดตั้งสำเร็จ... กรุณาพิมพ์คำสั่ง menu เพื่อไปยังขั้นตอนถัดไป"
echo "====================================================="
echo "-------- Script by www.เฮียเบิร์ด.com"
cd
rm -f /root/Install.sh

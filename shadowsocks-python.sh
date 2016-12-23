#!/usr/bin/env bash
#
# 2016-12-24 03:50
#
#     by:   fish
# mailto:   fishdev@qq.com
#

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

tmp_dir="/var/root/tmp"
mkdir -p ${tmp_dir}

#shadowsocks-python
shadowsocks_python="shadowsocks-python"
shadowsocks_python_init="/etc/init.d/shadowsocks-python"
shadowsocks_python_config="/etc/shadowsocks-python/config.json"
limits_conf="/etc/security/limits.conf"
sysctl_conf="/etc/sysctl.d/local.conf"

shadowsocks_python_url="https://github.com/shadowsocks/shadowsocks/archive/master.zip"
shadowsocks_python_init_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-python/master/etc/init.d/shadowsocks-python"
shadowsocks_python_config_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-python/master/etc/shadowsocks-python/config.json"
limits_conf_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-python/master/etc/security/limits.conf"
sysctl_conf_url="https://raw.githubusercontent.com/FishDDev/shadowsocks-python/master/etc/sysctl.d/local.conf"

#libsodium
libsodium_file="libsodium-1.0.11"
libsodium_url="https://github.com/jedisct1/libsodium/releases/download/1.0.11/libsodium-1.0.11.tar.gz"

check_root(){
[[ $EUID -ne 0 ]] && echo -e "${red}Error:${plain} This script must be run as root!" && exit 1
}

disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
fi
}

set_timezone(){
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate 1.cn.pool.ntp.org
}

install_yum(){
yum install -y unzip gzip openssl openssl-devel gcc swig python python-devel python-setuptools libtool libevent xmlto
yum install -y autoconf automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel asciidoc
}

download_shadowsocks_python(){
# get shadowsocks-python latest version
if ! wget "${shadowsocks_python_url}" -O "${tmp_dir}/${shadowsocks_python}.zip"; then
        rm -rf /var/root/tmp
        echo -e "${red}Error:${plain} Failed to download ${shadowsocks_python}.zip"
        exit 1
fi
# /etc/shadowsocks-python/config.json
mkdir -p /etc/shadowsocks-python
if ! wget "${shadowsocks_python_config_url}" -O "${shadowsocks_python_config}"; then 
    echo -e "${red}Error:${plain} Failed to download ${shadowsocks_python_config}"
fi
# /etc/init.d/shadowsocks-python
if ! wget "${shadowsocks_python_init_url}" -O "${shadowsocks_python_init}"; then 
    echo -e "${red}Error:${plain} Failed to download ${shadowsocks_python_init}"
fi

# /etc/init.d/shadowsocks-python
if ! wget "${libsodium_url}" -O "${tmp_dir}/${libsodium_file}.tar.gz"; then 
    echo -e "${red}Error:${plain} Failed to download ${shadowsocks_python_init}"
fi
}

install_libsodium(){
    cd ${tmp_dir}
    tar zxf ${libsodium_file}.tar.gz
    cd ${libsodium_file}
    ./configure && make && make install
    if [ $? -ne 0 ]; then
        echo "${red}${libsodium_file}${plain} install failed."
        install_cleanup
        exit 1
    fi
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf
    ldconfig
}

install_shadowsocks_python(){
cd /var/root/tmp
unzip -q ${shadowsocks_python}.zip
if [ $? -ne 1 ];then
        rm -rf ${shadowsocks_python}.zip
    else
        echo "unzip ${shadowsocks_python}.zip failed, please check unzip command."
fi

cd ${shadowsocks_python}*
python setup.py install --record /usr/local/shadowsocks_python.log

if [ $? -eq 0 ]; then
        chmod +x ${shadowsocks_python_init}
        chkconfig --add ${shadowsocks_python}
        chkconfig ${shadowsocks_python} on
        ${shadowsocks_python_init} start
        echo -e "${green}install successfully${plain}"
    else
        echo -e "${red}${shadowsocks_python}${plain} install failed."
fi
}

optimized_conf(){
sed -i '$a\ulimit -SHn 65535' /etc/profile;
# /etc/security/limits.conf
if ! wget "${limits_conf_url}" -O "${limits_conf}"; then 
    echo -e "${red}Error:${plain} Failed to download ${limits_conf}"
fi
# /etc/sysctl.d/local.conf
if ! wget "${sysctl_conf_url}" -O "${sysctl_conf}" && sysctl --system|sysctl -p; then 
    echo -e "${red}Error:${plain} Failed to download ${sysctl_conf}"
fi
if [ $? -eq 0 ]; then
       echo -e "${green}optimized config successfully${plain}"
    else
        echo -e "${red}optimized config${plain} install failed."
fi
}

check_root
set_timezone
disable_selinux
install_yum
download_shadowsocks_python
install_shadowsocks_python
optimized_conf
rm -rf /var/root/tmp
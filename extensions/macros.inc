%global debug_package %{nil}
%global php85_ver      8.5.8
%global php85_confdir  /etc/php85
%global php85_extdir   %{php85_confdir}/conf.d
%global php85_moddir   /usr/lib64/php85/modules
%define __phpize        /usr/bin/phpize
%define __phpconfig     /usr/bin/php-config

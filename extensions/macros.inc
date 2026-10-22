%global debug_package %{nil}
%global php_confdir  /etc/php%{php_major}
%global php_extdir   %{php_confdir}/conf.d
%global php_moddir   /usr/lib64/php%{php_major}/modules
%define __phpize        /usr/bin/phpize
%define __phpconfig     /usr/bin/php-config

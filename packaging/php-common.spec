# php%{php_major}-common subpackage fragment
# Included by php%{php_major}.spec — do not build standalone.

%package common
Summary:        Common files for PHP %{version}
Requires:       %{name} = %{version}-%{release}
Requires(pre):  shadow

%description common
Common files shared by PHP %{version} SAPIs and extensions, including
configuration directory structure and the php-fpm system user.

%pre common
getent group %{php_fpm_group} >/dev/null 2>&1 || groupadd -r %{php_fpm_group}
getent passwd %{php_fpm_user} >/dev/null 2>&1 || \
    useradd -r -g %{php_fpm_group} -d /var/lib/php%{php_major}-fpm -s /sbin/nologin \
    -c "PHP-FPM process owner" %{php_fpm_user}

%files common
%defattr(-,root,root,-)
%dir %attr(0755,root,root) %{php_confdir}
%dir %attr(0755,root,root) %{php_extdir}
%dir %attr(0755,root,root) %{php_moddir}
%dir %attr(0755,root,root) %{php_fpm_logdir}
%dir %attr(0755,root,root) /var/lib/php%{php_major}-fpm
%config(noreplace) %{php_confdir}/php.ini
%config(noreplace) %{php_extdir}/15-pdo.ini
%{php_moddir}/pdo.so
%ghost %attr(0644,root,root) %{php_fpm_rundir}

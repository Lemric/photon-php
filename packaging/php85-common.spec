# php85-common subpackage fragment
# Included by php85.spec — do not build standalone.

%package common
Summary:        Common files for PHP %{version}
Requires:       %{name} = %{version}-%{release}
Requires(pre):  shadow
BuildArch:      noarch

%description common
Common files shared by PHP %{version} SAPIs and extensions, including
configuration directory structure and the php-fpm system user.

%pre common
getent group %{php85_fpm_group} >/dev/null 2>&1 || groupadd -r %{php85_fpm_group}
getent passwd %{php85_fpm_user} >/dev/null 2>&1 || \
    useradd -r -g %{php85_fpm_group} -d /var/lib/php85-fpm -s /sbin/nologin \
    -c "PHP-FPM process owner" %{php85_fpm_user}

%files common
%defattr(-,root,root,-)
%dir %attr(0755,root,root) %{php85_confdir}
%dir %attr(0755,root,root) %{php85_extdir}
%dir %attr(0755,root,root) %{php85_moddir}
%dir %attr(0755,root,root) %{php85_fpm_logdir}
%dir %attr(0755,root,root) /var/lib/php85-fpm
%config(noreplace) %{php85_confdir}/php.ini
%ghost %attr(0644,root,root) %{php85_fpm_rundir}

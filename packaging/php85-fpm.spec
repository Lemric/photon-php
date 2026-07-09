# php85-fpm subpackage fragment
# Included by php85.spec — do not build standalone.

%package fpm
Summary:        FastCGI Process Manager for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       %{name}-cli = %{version}-%{release}
Requires(pre):  systemd
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

%description fpm
PHP-FPM (FastCGI Process Manager) is an alternative PHP FastCGI
implementation with advanced process management features.

%pre fpm
getent group %{php85_fpm_group} >/dev/null 2>&1 || groupadd -r %{php85_fpm_group}
getent passwd %{php85_fpm_user} >/dev/null 2>&1 || \
    useradd -r -g %{php85_fpm_group} -d /var/lib/php85-fpm -s /sbin/nologin \
    -c "PHP-FPM process owner" %{php85_fpm_user}

%post fpm
%systemd_post php85-php-fpm.service

%preun fpm
%systemd_preun php85-php-fpm.service

%postun fpm
%systemd_postun_with_restart php85-php-fpm.service

%files fpm
%defattr(-,root,root,-)
%{_sbindir}/php-fpm
%{_unitdir}/php85-php-fpm.service
%config(noreplace) %{php85_confdir}/php-fpm.conf
%config(noreplace) %{php85_confdir}/php-fpm.d
%{_mandir}/man8/php-fpm.8*

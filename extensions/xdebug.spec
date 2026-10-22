%include macros.inc

%define php_extname xdebug

Name:           php%{php_major}-pecl-xdebug
Version:        3.5.3
Release:        1%{?dist}
Summary:        PHP %{php_ver} Xdebug debugger extension (PECL, development only)
License:        PHP-3.01
URL:            https://xdebug.org/
Source0:        https://github.com/xdebug/xdebug/archive/%{version}/xdebug-%{version}.tar.gz

BuildRequires:  php%{php_major}-devel = %{php_ver}
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool

Requires:       php%{php_major}-common = %{php_ver}
Requires:       php%{php_major}-cli = %{php_ver}

%description
Xdebug is a debugging and profiling extension for PHP.
This package is intended for development environments only.

%prep
%autosetup -n xdebug-%{version}

%build
export CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC"
%{__phpize}
./configure
%make_build

%install
%make_install
install -d %{buildroot}%{php_extdir}
install -d %{buildroot}%{php_moddir}
if [ ! -f modules/xdebug.so ]; then
    echo "ERROR: xdebug.so was not built" >&2
    exit 1
fi
install -m 0755 modules/xdebug.so %{buildroot}%{php_moddir}/xdebug.so
cat > %{buildroot}%{php_extdir}/99-xdebug.ini << 'EOF'
zend_extension=xdebug.so
xdebug.mode=develop,debug
xdebug.start_with_request=trigger
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
xdebug.log=/var/log/php%{php_major}-fpm/xdebug.log
EOF
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php_moddir}/xdebug.so
%config(noreplace) %{php_extdir}/99-xdebug.ini

%changelog
* Thu Oct 22 2026 Photon PHP Build <build@photon-php.local> - 3.5.3-1
- Upgrade to 3.5.3; fetch sources from GitHub instead of pecl.php.net

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 3.5.0-3
- Rebuild against PHP 8.5.12

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 3.5.0-2
- Rebuild against PHP 8.5.11
- Fetch sources from PECL (xdebug.org unreachable from CI runners)

* Fri Jul 10 2026 Photon PHP Build <build@photon-php.local> - 3.5.0-1
- Upgrade for PHP 8.5 support

* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 3.4.2-1
- Initial Xdebug PECL build for PHP 8.5 on Photon OS (development)

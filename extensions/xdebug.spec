%include macros.inc

%define php85_extname xdebug

Name:           php85-pecl-xdebug
Version:        3.4.2
Release:        1%{?dist}
Summary:        PHP %{php85_ver} Xdebug debugger extension (PECL, development only)
License:        PHP-3.01
URL:            https://xdebug.org/
Source0:        https://xdebug.org/files/xdebug-%{version}.tgz

BuildRequires:  php85-devel = %{php85_ver}
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool

Requires:       php85-common = %{php85_ver}
Requires:       php85-cli = %{php85_ver}

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
install -d %{buildroot}%{php85_extdir}
install -d %{buildroot}%{php85_moddir}
if [ -f modules/xdebug.so ]; then
    install -m 0755 modules/xdebug.so %{buildroot}%{php85_moddir}/xdebug.so
fi
cat > %{buildroot}%{php85_extdir}/99-xdebug.ini << 'EOF'
zend_extension=xdebug.so
xdebug.mode=develop,debug
xdebug.start_with_request=trigger
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
xdebug.log=/var/log/php85-fpm/xdebug.log
EOF
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php85_moddir}/xdebug.so
%config(noreplace) %{php85_extdir}/99-xdebug.ini

%changelog
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 3.4.2-1
- Initial Xdebug PECL build for PHP 8.5 on Photon OS (development)

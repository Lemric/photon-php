%include macros.inc

%define php_extname amqp

Name:           php%{php_major}-pecl-amqp
Version:        2.2.0
Release:        4%{?dist}
Summary:        PHP %{php_ver} AMQP extension (PECL)
License:        PHP-3.01
URL:            https://github.com/php-amqp/php-amqp
Source0:        https://github.com/php-amqp/php-amqp/archive/v%{version}/amqp-%{version}.tar.gz

BuildRequires:  php%{php_major}-devel = %{php_ver}
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  pkg-config
BuildRequires:  rabbitmq-c-devel

Requires:       php%{php_major}-common = %{php_ver}
Requires:       php%{php_major}-cli = %{php_ver}
Requires:       rabbitmq-c

%description
The AMQP extension provides connectivity to RabbitMQ and other
AMQP-compatible message brokers via the rabbitmq-c library.

%prep
%autosetup -n php-amqp-%{version}

%build
export CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC"
export PKG_CONFIG_PATH=%{_libdir}/pkgconfig
%{__phpize}
./configure
%make_build

%install
%make_install
install -d %{buildroot}%{php_extdir}
install -d %{buildroot}%{php_moddir}
if [ ! -f modules/amqp.so ]; then
    echo "ERROR: amqp.so was not built" >&2
    exit 1
fi
install -m 0755 modules/amqp.so %{buildroot}%{php_moddir}/amqp.so
echo "extension=amqp.so" > %{buildroot}%{php_extdir}/30-amqp.ini
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php_moddir}/amqp.so
%config(noreplace) %{php_extdir}/30-amqp.ini

%changelog
* Thu Oct 22 2026 Photon PHP Build <build@photon-php.local> - 2.2.0-4
- Fetch sources from GitHub instead of pecl.php.net

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 2.2.0-3
- Rebuild against PHP 8.5.12

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 2.2.0-2
- Rebuild against PHP 8.5.11

* Fri Jul 10 2026 Photon PHP Build <build@photon-php.local> - 2.2.0-1
- Upgrade for PHP 8.5 (ext/standard/datetime.h and zend_exception_get_default removed)

* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 2.1.2-1
- Initial AMQP PECL build for PHP 8.5 on Photon OS

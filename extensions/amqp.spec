%include macros.inc

%define php85_extname amqp

Name:           php85-pecl-amqp
Version:        2.2.0
Release:        1%{?dist}
Summary:        PHP %{php85_ver} AMQP extension (PECL)
License:        PHP-3.01
URL:            https://pecl.php.net/package/amqp
Source0:        https://pecl.php.net/get/amqp-%{version}.tgz

BuildRequires:  php85-devel = %{php85_ver}
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  pkg-config
BuildRequires:  rabbitmq-c-devel

Requires:       php85-common = %{php85_ver}
Requires:       php85-cli = %{php85_ver}
Requires:       rabbitmq-c

%description
The AMQP extension provides connectivity to RabbitMQ and other
AMQP-compatible message brokers via the rabbitmq-c library.

%prep
%autosetup -n amqp-%{version}

%build
export CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC"
export PKG_CONFIG_PATH=%{_libdir}/pkgconfig
%{__phpize}
./configure
%make_build

%install
%make_install
install -d %{buildroot}%{php85_extdir}
install -d %{buildroot}%{php85_moddir}
if [ ! -f modules/amqp.so ]; then
    echo "ERROR: amqp.so was not built" >&2
    exit 1
fi
install -m 0755 modules/amqp.so %{buildroot}%{php85_moddir}/amqp.so
echo "extension=amqp.so" > %{buildroot}%{php85_extdir}/30-amqp.ini
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php85_moddir}/amqp.so
%config(noreplace) %{php85_extdir}/30-amqp.ini

%changelog
* Fri Jul 10 2026 Photon PHP Build <build@photon-php.local> - 2.2.0-1
- Upgrade for PHP 8.5 (ext/standard/datetime.h and zend_exception_get_default removed)

* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 2.1.2-1
- Initial AMQP PECL build for PHP 8.5 on Photon OS

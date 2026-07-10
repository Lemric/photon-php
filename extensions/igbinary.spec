%include macros.inc

%define php85_extname igbinary

Name:           php85-pecl-igbinary
Version:        3.2.17RC1
Release:        2%{?dist}
Summary:        PHP %{php85_ver} igbinary serializer extension (PECL)
License:        PHP-3.01
URL:            https://pecl.php.net/package/igbinary
Source0:        https://pecl.php.net/get/igbinary-%{version}.tgz

BuildRequires:  php85-devel = %{php85_ver}
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool

Requires:       php85-common = %{php85_ver}
Requires:       php85-cli = %{php85_ver}

%description
Igbinary is a drop-in replacement for the standard PHP serializer.
It stores PHP data structures in a compact binary form.

%prep
%autosetup -n igbinary-%{version}

%build
export CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC"
%{__phpize}
./configure
%make_build

%install
%make_install
install -d %{buildroot}%{php85_extdir}
install -d %{buildroot}%{php85_moddir}
if [ ! -f modules/igbinary.so ]; then
    echo "ERROR: igbinary.so was not built" >&2
    exit 1
fi
install -m 0755 modules/igbinary.so %{buildroot}%{php85_moddir}/igbinary.so
echo "extension=igbinary.so" > %{buildroot}%{php85_extdir}/30-igbinary.ini
install -d %{buildroot}/usr/include/php85/php/ext/igbinary
install -m 0644 igbinary.h php_igbinary.h \
    %{buildroot}/usr/include/php85/php/ext/igbinary/
install -m 0644 src/php7/igbinary.h src/php7/php_igbinary.h \
    %{buildroot}/usr/include/php85/php/ext/igbinary/
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php85_moddir}/igbinary.so
%config(noreplace) %{php85_extdir}/30-igbinary.ini
/usr/include/php85/php/ext/igbinary/

%changelog
* Fri Jul 10 2026 Photon PHP Build <build@photon-php.local> - 3.2.17RC1-2
- Ship igbinary.h headers required to build php85-pecl-redis

* Fri Jul 10 2026 Photon PHP Build <build@photon-php.local> - 3.2.17RC1-1
- Upgrade for PHP 8.5 (php_smart_string.h removed upstream)

* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 3.2.16-1
- Initial igbinary PECL build for PHP 8.5 on Photon OS

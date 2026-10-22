%include macros.inc

%define php_extname imagick

Name:           php%{php_major}-pecl-imagick
Version:        3.8.1
Release:        4%{?dist}
Summary:        PHP %{php_ver} ImageMagick extension (PECL)
License:        PHP-3.01
URL:            https://github.com/Imagick/imagick
Source0:        https://github.com/Imagick/imagick/archive/%{version}/imagick-%{version}.tar.gz

BuildRequires:  php%{php_major}-devel = %{php_ver}
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  pkg-config
BuildRequires:  ImageMagick-devel

Requires:       php%{php_major}-common = %{php_ver}
Requires:       php%{php_major}-cli = %{php_ver}
Requires:       ImageMagick

%description
Imagick is a native PHP extension to create and modify images using
the ImageMagick API.

%prep
%autosetup -n imagick-%{version}

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
if [ -f modules/imagick.so ]; then
    install -m 0755 modules/imagick.so %{buildroot}%{php_moddir}/imagick.so
fi
echo "extension=imagick.so" > %{buildroot}%{php_extdir}/30-imagick.ini
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php_moddir}/imagick.so
%config(noreplace) %{php_extdir}/30-imagick.ini

%changelog
* Thu Oct 22 2026 Photon PHP Build <build@photon-php.local> - 3.8.1-4
- Fetch sources from GitHub instead of pecl.php.net

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 3.8.1-3
- Rebuild against PHP 8.5.12

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 3.8.1-2
- Rebuild against PHP 8.5.11

* Fri Jul 10 2026 Photon PHP Build <build@photon-php.local> - 3.8.1-1
- Upgrade for PHP 8.5 (php_smart_string.h removed upstream)

* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 3.7.0-1
- Initial imagick PECL build for PHP 8.5 on Photon OS

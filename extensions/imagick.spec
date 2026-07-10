%include macros.inc

%define php85_extname imagick

Name:           php85-pecl-imagick
Version:        3.8.1
Release:        1%{?dist}
Summary:        PHP %{php85_ver} ImageMagick extension (PECL)
License:        PHP-3.01
URL:            https://pecl.php.net/package/imagick
Source0:        https://pecl.php.net/get/imagick-%{version}.tgz

BuildRequires:  php85-devel = %{php85_ver}
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  pkg-config
BuildRequires:  ImageMagick-devel

Requires:       php85-common = %{php85_ver}
Requires:       php85-cli = %{php85_ver}
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
install -d %{buildroot}%{php85_extdir}
install -d %{buildroot}%{php85_moddir}
if [ -f modules/imagick.so ]; then
    install -m 0755 modules/imagick.so %{buildroot}%{php85_moddir}/imagick.so
fi
echo "extension=imagick.so" > %{buildroot}%{php85_extdir}/30-imagick.ini
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php85_moddir}/imagick.so
%config(noreplace) %{php85_extdir}/30-imagick.ini

%changelog
* Fri Jul 10 2026 Photon PHP Build <build@photon-php.local> - 3.8.1-1
- Upgrade for PHP 8.5 (php_smart_string.h removed upstream)

* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 3.7.0-1
- Initial imagick PECL build for PHP 8.5 on Photon OS

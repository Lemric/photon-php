%include macros.inc

%define php_extname apcu

Name:           php%{php_major}-pecl-apcu
Version:        5.1.28
Release:        1%{?dist}
Summary:        PHP %{php_ver} APCu user cache extension (PECL)
License:        PHP-3.01
URL:            https://github.com/krakjoe/apcu
Source0:        https://github.com/krakjoe/apcu/archive/v%{version}/apcu-%{version}.tar.gz

BuildRequires:  php%{php_major}-devel = %{php_ver}
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool

Requires:       php%{php_major}-common = %{php_ver}
Requires:       php%{php_major}-cli = %{php_ver}

%description
APCu is a userland caching module for PHP offering an object cache
for storing arbitrary data in shared memory.

%prep
%autosetup -n apcu-%{version}

%build
export CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC"
%{__phpize}
./configure
%make_build

%install
%make_install
install -d %{buildroot}%{php_extdir}
install -d %{buildroot}%{php_moddir}
if [ ! -f modules/apcu.so ]; then
    echo "ERROR: apcu.so was not built" >&2
    exit 1
fi
install -m 0755 modules/apcu.so %{buildroot}%{php_moddir}/apcu.so
cat > %{buildroot}%{php_extdir}/30-apcu.ini << 'EOF'
extension=apcu.so
apc.enabled=1
apc.shm_size=128M
apc.ttl=7200
apc.enable_cli=0
EOF
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php_moddir}/apcu.so
%config(noreplace) %{php_extdir}/30-apcu.ini

%changelog
* Thu Oct 22 2026 Photon PHP Build <build@photon-php.local> - 5.1.28-1
- Upgrade to 5.1.28; fetch sources from GitHub instead of pecl.php.net

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 5.1.24-3
- Rebuild against PHP 8.5.12

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 5.1.24-2
- Rebuild against PHP 8.5.11

* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 5.1.24-1
- Initial APCu PECL build for PHP 8.5 on Photon OS

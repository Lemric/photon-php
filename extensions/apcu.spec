%include macros.inc

%define php85_extname apcu

Name:           php85-pecl-apcu
Version:        5.1.24
Release:        1%{?dist}
Summary:        PHP %{php85_ver} APCu user cache extension (PECL)
License:        PHP-3.01
URL:            https://pecl.php.net/package/APCu
Source0:        https://pecl.php.net/get/apcu-%{version}.tgz

BuildRequires:  php85-devel = %{php85_ver}
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool

Requires:       php85-common = %{php85_ver}
Requires:       php85-cli = %{php85_ver}

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
install -d %{buildroot}%{php85_extdir}
install -d %{buildroot}%{php85_moddir}
if [ ! -f modules/apcu.so ]; then
    echo "ERROR: apcu.so was not built" >&2
    exit 1
fi
install -m 0755 modules/apcu.so %{buildroot}%{php85_moddir}/apcu.so
cat > %{buildroot}%{php85_extdir}/30-apcu.ini << 'EOF'
extension=apcu.so
apc.enabled=1
apc.shm_size=128M
apc.ttl=7200
apc.enable_cli=0
EOF
find %{buildroot} -name '*.so' -exec strip --strip-unneeded {} \;

%files
%defattr(-,root,root,-)
%{php85_moddir}/apcu.so
%config(noreplace) %{php85_extdir}/30-apcu.ini

%changelog
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 5.1.24-1
- Initial APCu PECL build for PHP 8.5 on Photon OS

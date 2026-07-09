# libzip — ZIP library required by PHP zip extension
# Not available in Photon OS 5.x default repositories.

%global libzip_ver 1.11.4

Name:           libzip
Version:        %{libzip_ver}
Release:        1%{?dist}
Summary:        ZIP archive compatibility library
License:        BSD-3-Clause
URL:            https://libzip.org/
Source0:        https://github.com/nih-at/libzip/releases/download/v%{libzip_ver}/libzip-%{libzip_ver}.tar.gz

BuildRequires:  gcc
BuildRequires:  libstdc++-devel
BuildRequires:  cmake
BuildRequires:  make
BuildRequires:  pkg-config
BuildRequires:  zlib-devel
BuildRequires:  openssl-devel

%description
libzip is a C library for reading, creating, and modifying ZIP archives.
Required by the php85-zip extension on Photon OS.

%prep
%autosetup -n libzip-%{version}

%build
%cmake -DCMAKE_BUILD_TYPE=Release \
       -DENABLE_GNUTLS=OFF \
       -DENABLE_MBEDTLS=OFF \
       -DENABLE_OPENSSL=ON \
       -DBUILD_DOC=OFF \
       -DBUILD_EXAMPLES=OFF \
       -DBUILD_REGRESS=OFF \
       -DBUILD_TOOLS=ON
%cmake_build

%install
%cmake_install
find %{buildroot} -name '*.so*' -exec strip --strip-unneeded {} \; 2>/dev/null || true

%files
%license LICENSE
%{_libdir}/libzip.so*
%{_bindir}/zipcmp
%{_bindir}/zipmerge
%{_bindir}/ziptool

%package devel
Summary:        Development files for libzip
Requires:       %{name} = %{version}-%{release}

%description devel
Header files and pkg-config metadata for building against libzip.

%files devel
%{_libdir}/pkgconfig/libzip.pc
%{_includedir}/zip.h
%{_includedir}/zipconf.h

%changelog
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 1.11.4-1
- Bump to libzip 1.11.4 (.tar.gz release tarball)
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 1.11.3-1
- Initial libzip build for Photon OS PHP zip extension

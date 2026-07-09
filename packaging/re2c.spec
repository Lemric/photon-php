# re2c - lexer generator required by PHP 8.5+ (>= 3.x)
# Photon OS 5.x ships re2c 1.x; this package satisfies PHP build requirements.

%global re2c_ver 3.1
%global debug_package %{nil}

Name:           re2c
Version:        %{re2c_ver}
Release:        1%{?dist}
Summary:        Lexer generator for C/C++/Go/D (PHP build dependency)
License:        Public Domain
URL:            https://re2c.org/
Source0:        https://github.com/skvadrik/re2c/releases/download/%{version}/re2c-%{version}.tar.xz

BuildRequires:  gcc
BuildRequires:  libstdc++-devel
BuildRequires:  glibc-devel
BuildRequires:  linux-api-headers
BuildRequires:  make
BuildRequires:  cmake
BuildRequires:  python3

%description
re2c is a lexer generator that produces very fast lexers from regular
expressions. PHP 8.5+ requires re2c >= 3.x for building from source.

%prep
%autosetup -n re2c-%{version}

%build
%cmake -DCMAKE_BUILD_TYPE=Release -DRE2C_BUILD_RE2GO=OFF -DRE2C_BUILD_RE2RUST=OFF -DRE2C_BUILD_TESTS=OFF
%cmake_build

%install
%cmake_install
strip %{buildroot}%{_bindir}/re2c 2>/dev/null || true

%files
%license LICENSE
%{_bindir}/re2c
%{_datadir}/re2c
%{_mandir}/man1/re2c.1*

%changelog
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 3.1-1
- Initial re2c 3.x package for Photon OS PHP builds

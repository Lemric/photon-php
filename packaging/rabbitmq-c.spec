# rabbitmq-c — AMQP C client library for php85-pecl-amqp
# Photon OS 5.x may not ship this package; build before AMQP extension.

%global rabbitmq_c_ver 0.14.0

Name:           rabbitmq-c
Version:        %{rabbitmq_c_ver}
Release:        1%{?dist}
Summary:        AMQP C client library
License:        MIT
URL:            https://github.com/alanxz/rabbitmq-c
Source0:        https://github.com/alanxz/rabbitmq-c/archive/v%{version}/rabbitmq-c-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  cmake
BuildRequires:  make
BuildRequires:  openssl-devel
BuildRequires:  libxml2-devel

%description
rabbitmq-c is a C-language AMQP client library for use with AMQP servers
such as RabbitMQ. Required by the php85-pecl-amqp extension.

%prep
%autosetup -n rabbitmq-c-%{version}

%build
%cmake -DCMAKE_BUILD_TYPE=Release \
       -DBUILD_API_DOCS=OFF \
       -DBUILD_EXAMPLES=OFF \
       -DBUILD_TESTS=OFF \
       -DBUILD_TOOLS=OFF \
       -DENABLE_SSL_SUPPORT=ON
%cmake_build

%install
%cmake_install
find %{buildroot} -name '*.so*' -exec strip --strip-unneeded {} \; 2>/dev/null || true

%files
%license LICENSE
%{_libdir}/librabbitmq.so*
%{_libdir}/pkgconfig/librabbitmq.pc
%{_includedir}/amqp.h
%{_includedir}/amqp_*.h
%{_includedir}/rabbitmq-c/

%changelog
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 0.14.0-1
- Initial rabbitmq-c build for Photon OS PHP AMQP extension

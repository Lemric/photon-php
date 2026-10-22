# php%{php_major}-devel subpackage fragment
# Included by php%{php_major}.spec — do not build standalone.

%package devel
Summary:        Files needed for building PHP %{version} extensions
Requires:       %{name}-cli = %{version}-%{release}
Requires:       %{name}-common = %{version}-%{release}
Requires:       autoconf
Requires:       automake
Requires:       libtool
Requires:       pkg-config

%description devel
Development files for building PECL extensions against PHP %{version}.
Includes phpize, php-config, headers, and the embedded SAPI library.

%files devel
%defattr(-,root,root,-)
%{_bindir}/phpize
%{_bindir}/php-config
%{_includedir}/php%{php_major}
%{_libdir}/libphp%{php_major}.so*
%{_libdir}/php/build
%{_mandir}/man1/phpize.1*
%{_mandir}/man1/php-config.1*

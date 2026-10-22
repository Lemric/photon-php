# php%{php_major}-cli subpackage fragment
# Included by php%{php_major}.spec — do not build standalone.

%package cli
Summary:        Command-line interface for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libxml2
Requires:       openssl
Requires:       zlib
Requires:       libargon2

%description cli
The php%{php_major}-cli package contains the PHP command-line executable.

%files cli
%defattr(-,root,root,-)
%{_bindir}/php
%{_mandir}/man1/php.1*

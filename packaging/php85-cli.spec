# php85-cli subpackage fragment
# Included by php85.spec — do not build standalone.

%package cli
Summary:        Command-line interface for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libxml2
Requires:       openssl
Requires:       zlib

%description cli
The php85-cli package contains the PHP command-line executable.

%files cli
%defattr(-,root,root,-)
%{_bindir}/php
%{_mandir}/man1/php.1*

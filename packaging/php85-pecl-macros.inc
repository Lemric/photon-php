# php85-pecl-macros — shared macros for PECL extension builds
%global php85_ver          8.5.8
%global php85_api          20250925
%global php85_zend_api     420250925
%global php85_confdir      /etc/php85
%global php85_extdir       %{php85_confdir}/conf.d
%global php85_moddir       /usr/lib64/php85/modules
%global php85_extname      %{?php85_extname:%{php85_extname}}

%global php85_configure %{__phpize} && ./configure %{?php85_configure_opts}

%global php85_make_install \
    %make_install && \
    install -d %{buildroot}%{php85_extdir} && \
    echo "extension=%{php85_extname}.so" > %{buildroot}%{php85_extdir}/30-%{php85_extname}.ini && \
    find %{buildroot}%{php85_moddir} -name '*.so' -exec strip --strip-unneeded {} \; 2>/dev/null || true

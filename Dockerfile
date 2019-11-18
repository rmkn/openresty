FROM rmkn/centos7
LABEL maintainer "rmkn"

ENV OPENRESTY_VERSION 1.15.8.2
ENV OPENSSL_VERSION 1.1.1d
ENV PCRE_VERSION 8.43
ENV ZLIB_VERSION 1.2.11

RUN yum install -y perl make gcc gcc-c++ pcre-devel ccache systemtap-sdt-devel patch

RUN curl -o /usr/local/src/zlib.tar.gz -SL https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/zlib.tar.gz -C /usr/local/src \
	&& cd /usr/local/src/zlib-${ZLIB_VERSION}  \
	&& ./configure --prefix=/usr/local/openresty/zlib \
	&& make CFLAGS='-O3 -D_LARGEFILE64_SOURCE=1 -DHAVE_HIDDEN -g' SFLAGS='-O3 -fPIC -D_LARGEFILE64_SOURCE=1 -DHAVE_HIDDEN -g' \
	&& make install

RUN curl -o /usr/local/src/openssl.tar.gz -SL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/openssl.tar.gz -C /usr/local/src \
	&& cd /usr/local/src/openssl-${OPENSSL_VERSION} \
	&& curl -o sess_set_get_cb_yield.patch -SL https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-1.1.1c-sess_set_get_cb_yield.patch \
	&& patch -p1 < sess_set_get_cb_yield.patch \
	&& ./config no-threads shared zlib -g enable-ssl3 enable-ssl3-method --prefix=/usr/local/openresty/openssl --libdir=lib -I/usr/local/openresty/zlib/include -L/usr/local/openresty/zlib/lib -Wl,-rpath,/usr/local/openresty/zlib/lib:/usr/local/openresty/openssl/lib \
	&& make CC='ccache gcc -fdiagnostics-color=always' \
	&& make install_sw

RUN curl -o /usr/local/src/pcre.tar.gz -SL https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/pcre.tar.gz -C /usr/local/src \
	&& cd /usr/local/src/pcre-${PCRE_VERSION} \
	&& ./configure --prefix=/usr/local/openresty/pcre --libdir=/usr/local/openresty/pcre/lib --disable-cpp --enable-jit --enable-utf --enable-unicode-properties \
	&& make CC='ccache gcc -fdiagnostics-color=always' V=1 \
	&& make install

RUN curl -o /usr/local/src/openresty.tar.gz -SL https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/openresty.tar.gz -C /usr/local/src \
	&& cd /usr/local/src/openresty-${OPENRESTY_VERSION} \
	&& ./configure \
		--prefix="/usr/local/openresty" \
		--with-cc='ccache gcc -fdiagnostics-color=always' \
		--with-cc-opt="-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/zlib/include -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include" \
		--with-ld-opt="-L/usr/local/openresty/zlib/lib -L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/zlib/lib:/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib" \
		--with-pcre-jit \
		--without-http_rds_json_module \
		--without-http_rds_csv_module \
		--without-lua_rds_parser \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-http_v2_module \
		--without-mail_pop3_module \
		--without-mail_imap_module \
		--without-mail_smtp_module \
		--with-http_stub_status_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_auth_request_module \
		--with-http_secure_link_module \
		--with-http_random_index_module \
		--with-http_gzip_static_module \
		--with-http_sub_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module \
		--with-threads \
		--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT' \
		--with-dtrace-probes \
	&& gmake \
	&& gmake install

RUN ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/bin/openresty

RUN rm -rf /usr/local/openresty/zlib/share \
	&& rm -f  /usr/local/openresty/zlib/lib/*.la \
	&& rm -rf /usr/local/openresty/zlib/lib/pkgconfig \
	&& rm -f  /usr/local/openresty/zlib/lib/*.a \
	&& rm -rf /usr/local/openresty/zlib/include \
	&& rm -rf /usr/local/openresty/openssl/bin/c_rehash \
	&& rm -rf /usr/local/openresty/openssl/lib/pkgconfig \
	&& rm -rf /usr/local/openresty/openssl/misc \
	&& rm -f  /usr/local/openresty/openssl/lib/*.a \
	&& rm -rf /usr/local/openresty/openssl/include \
	&& rm -rf /usr/local/openresty/pcre/bin \
	&& rm -rf /usr/local/openresty/pcre/share \
	&& rm -f  /usr/local/openresty/pcre/lib/*.la \
	&& rm -f  /usr/local/openresty/pcre/lib/*pcrecpp* \
	&& rm -f  /usr/local/openresty/pcre/lib/*pcreposix* \
	&& rm -rf /usr/local/openresty/pcre/lib/pkgconfig \
	&& rm -f  /usr/local/openresty/pcre/lib/*.a \
	&& rm -rf /usr/local/openresty/pcre/include \
	&& rm -rf /usr/local/openresty/luajit/share/man \
	&& rm -rf /usr/local/openresty/luajit/lib/libluajit-5.1.a \
	&& rm -f  /usr/local/openresty/bin/resty \
	&& rm -f  /usr/local/openresty/bin/restydoc \
	&& rm -f  /usr/local/openresty/bin/restydoc-index \
	&& rm -f  /usr/local/openresty/bin/md2pod.pl \
	&& rm -f  /usr/local/openresty/bin/nginx-xml2pod \
	&& rm -f  /usr/local/openresty/resty.index \
	&& rm -rf /usr/local/openresty/pod \
	&& rm -rf /usr/local/openresty/bin/opm \
	&& rm -rf /usr/local/openresty/site/manifest \
	&& rm -rf /usr/local/openresty/site/pod

COPY nginx.conf /usr/local/openresty/nginx/conf/
COPY default.conf security.conf /usr/local/openresty/nginx/conf/conf.d/

EXPOSE 80 443

CMD ["/usr/bin/openresty", "-g", "daemon off;"]


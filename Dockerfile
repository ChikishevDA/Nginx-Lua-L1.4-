FROM debian:9 AS builder
ENV NGINX_V="1.19.3" NDK_V="0.3.0" LUAJIT_V="2.0.5" LUA_V="0.10.9rc7" LRC="0.1.23" LRL="0.13"
RUN apt update && apt install -y \
libssl-dev libgeoip-dev libpcre++-dev libxml2-dev libyajl-dev zlib1g-dev \
wget gcc make nano
WORKDIR	/usr/local/src/
# Download ngx_devel_kit(NDK) 
RUN wget https://github.com/vision5/ngx_devel_kit/archive/refs/tags/v${NDK_V}.tar.gz \
&& tar -zxvf v${NDK_V}.tar.gz 
# Download ngx_lua
RUN wget https://github.com/openresty/lua-nginx-module/archive/v${LUA_V}.tar.gz \
&& tar -zxvf v${LUA_V}.tar.gz
# Download and install LuaJIT 2.x
RUN wget http://luajit.org/download/LuaJIT-${LUAJIT_V}.tar.gz \
&& tar -zxvf LuaJIT-${LUAJIT_V}.tar.gz \
&& cd LuaJIT-${LUAJIT_V} \
&& make install PREFIX=/usr/local/luajit
# Download and install nginx
RUN wget https://nginx.org/download/nginx-${NGINX_V}.tar.gz \
&& tar -zxvf nginx-${NGINX_V}.tar.gz\
&& cd  nginx-${NGINX_V} \
&& export LUAJIT_LIB=/usr/local/luajit/lib \
&& export LUAJIT_INC=/usr/local/luajit/include/luajit-2.0 \
&& ./configure \
--with-ld-opt="-Wl,-rpath,/usr/local/luajit/lib" \
--add-module=/usr/local/src/ngx_devel_kit-${NDK_V} \
--add-module=/usr/local/src/lua-nginx-module-${LUA_V} \
&& make && make install

FROM debian:9
COPY --from=builder /usr/local/luajit /usr/local/luajit
COPY --from=builder /usr/local/nginx /usr/local/nginx
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]

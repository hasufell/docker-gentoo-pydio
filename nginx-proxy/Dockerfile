FROM        hasufell/gentoo-nginx:20150820
MAINTAINER  Julian Ospald <hasufell@gentoo.org>

## nginx-proxy
COPY nginx.tmpl /app/nginx.tmpl
COPY Procfile /app/Procfile
COPY sites-enabled/proxy.conf /etc/nginx/sites-enabled/proxy.conf

# see: https://www.digicert.com/csr-creation-apache.htm

openssl req -new -newkey rsa:2048 -nodes -keyout nginx-proxy/ssl/server/server.key -out nginx-proxy/ssl/server/server.csr

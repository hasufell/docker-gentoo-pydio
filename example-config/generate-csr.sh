# see: https://www.digicert.com/csr-creation-apache.htm

openssl req -new -newkey rsa:2048 -nodes -keyout ssl/certs/server.key -out ssl/certs/server.csr

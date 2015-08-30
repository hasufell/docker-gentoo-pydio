# see: https://www.digicert.com/csr-creation-apache.htm

openssl req -new -newkey rsa:2048 -nodes -keyout ssl/server/server.key -out ssl/server/server.csr

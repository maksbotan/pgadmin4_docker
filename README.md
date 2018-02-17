Dockerfile for PgAdmin4
=======================

See <https://www.pgadmin.org/> for the original project.

Starting with PgAdmin 2.1 upstream makes official docker image dpage/pgadmin4
(<https://hub.docker.com/r/dpage/pgadmin4/>).

However, I think this docker image has a number of issues:

- It is based on `centos` base image. This means it contains a lot of bloated / unneeded thing, and
probably outdated packages
- It embeds full Apache web server with `mod_wsgi`
- It is based on Python 2.7
- It does not include `pg_dump` and other tools
- It is built with a complicated script building stuff on the host

Therefore I decided to make this image. Here are its key features:

- Main image is based on `python:3.6-alpine3.7`. Using Alpine linux leads to much smaller image
- All build is done with Docker multi-stage build. First of all I build the frontend in `node:6` image,
then I build `psycopg2` and `pycrypto` wheels in python image and in the end I just install all
dependencies in a clean `python:3.6-alpine3.7` image, so that it does not have any leftovers from the build
process
- I use waitress (<https://docs.pylonsproject.org/projects/waitress/en/latest/>) as lightweight HTTP / WSGI
server. I deliberately skip any SSL support as this should be done by reverse-proxy like Nginx forwarding
requests to PgAdmin container if you want to make it available to public
- I install Alpine `postgresql-client` package, which includes `pg_dump` and other tools and I config
PgAdmin to find these tools by default
- I byte-compile all PgAdmin Python code in Dockerfile with optimization (`-O`) enabled. This way Python
does not have to compile modules on each container restart and consume space in overlay fs

Official image occupies 558MB when uncompressed, while my image needs only 169MB.

Usage
-----

This image has two mandatory configuration environment variables and one optional:

- `PGADMIN_SETUP_EMAIL` -- email for default account
- `PGADMIN_SETUP_PASSWORD` -- password for default account
- `PGADMIN_WAITRESS_THREADS` -- number of waitress thread workers to start, default is 4

You can mount `/var/lib/pgadmin` to make PgAdmin configuration persistent. 

PgAdmin4 will listen for HTTP connections on port 8080.

Sample `docker run` command:

```
docker run -d \
    -e PGADMIN_SETUP_EMAIL=.... \
    -e PGADMIN_SETUP_PASSWORD=.... \
    -v pgadmin_data:/var/lib/pgadmin \
    -p 8080:8080 \
    maksbotan/pgadmin4
```

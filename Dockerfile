# First of all, build frontend with NodeJS in a separate builder container
# Node-6 with ABI v48 is supported by all needed C++ packages
FROM node:6 AS node-builder

COPY ./pgadmin4/web/ /pgadmin4/web/
WORKDIR /pgadmin4/web

RUN yarn install --cache-folder ./ycache --verbose && \
    yarn run bundle && \
    rm -rf ./ycache ./pgadmin/static/js/generated/.cache

# Then install backend, copy static files and set up entrypoint
# Need alpine3.7 to get pg_dump and friends in postgresql-client package
FROM python:3.6-alpine3.7

RUN pip --no-cache-dir install waitress
RUN apk add --no-cache postgresql-client postgresql-libs

# Install build-dependencies, build & install C extensions and purge deps in one RUN step
# so that deps do not increase the size of resulting image by remaining in layers
RUN set -ex && \
    apk add --no-cache --virtual build-deps build-base postgresql-dev && \
    pip install --no-cache-dir psycopg2 pycrypto && \
    apk del --no-cache build-deps

COPY --from=node-builder /pgadmin4/web/pgadmin/static/js/generated/ /pgadmin4/pgadmin/static/js/generated/

COPY ./pgadmin4/web /pgadmin4
COPY ./pgadmin4/requirements.txt /pgadmin4
COPY ./run_pgadmin.py /pgadmin4
COPY ./config_distro.py /pgadmin4

WORKDIR /pgadmin4
ENV PYTHONPATH=/pgadmin4

RUN pip install --no-cache-dir -r requirements.txt

# Precompile and optimize python code to save time and space on startup
RUN python -O -m compileall /pgadmin4

VOLUME /var/lib/pgadmin
EXPOSE 8080

ENTRYPOINT ["python", "/pgadmin4/run_pgadmin.py"]

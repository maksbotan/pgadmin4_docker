# First of all, build frontend with NodeJS in a separate builder container
# Node-6 with ABI v48 is supported by all needed C++ packages
FROM node:6 AS node-builder

COPY ./pgadmin4/web/ /pgadmin4/web/
WORKDIR /pgadmin4/web

RUN yarn install --cache-folder ./ycache --verbose && \
    yarn run bundle && \
    rm -rf ./ycache ./pgadmin/static/js/generated/.cache

# Then compile python C extensions into wheels to avoid having build deps in main container
FROM python:3.6-alpine3.7 AS python-builder

COPY ./compile_python.sh /build/
WORKDIR /build
RUN apk add --no-cache postgresql-libs postgresql-dev build-base
RUN set -ex && \
    ./compile_python.sh psycopg2 && \
    ./compile_python.sh pycrypto

# Then install everything and set up entrypoint
# Need alpine3.7 to get pg_dump and friends in postgresql-client package
FROM python:3.6-alpine3.7

RUN pip --no-cache-dir install waitress
RUN apk add --no-cache postgresql-client postgresql-libs

COPY --from=python-builder /build/wheels/*.whl /pgadmin4/wheels/
COPY --from=node-builder /pgadmin4/web/pgadmin/static/js/generated/ /pgadmin4/pgadmin/static/js/generated/

RUN set -ex && \
    pip install /pgadmin4/wheels/*.whl && \
    rm -rf /pgadmin4/wheels

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

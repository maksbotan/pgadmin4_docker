#!/bin/sh

if [ ! -f /var/lib/pgadmin/pgadmin4.db ]; then
    if [ -z ${PGADMIN_SETUP_EMAIL} -o -z ${PGADMIN_SETUP_PASSWORD} ]; then
        echo 'You need to specify PGADMIN_SETUP_EMAIL and PGADMIN_SETUP_PASSWORD environment variables'
        exit 1
    fi

    # Initialize DB before starting Gunicorn
    # Importing pgadmin4 (from this script) is enough
    python run_pgadmin.py
fi

# NOTE: currently pgadmin can run only with 1 worker due to sessions implementation
# Using --threads to have multi-threaded single-process worker

if [ ! -z ${PGADMIN_ENABLE_TLS} ]; then
    exec gunicorn --bind 0.0.0.0:8080 -w 1 --threads ${GUNICORN_THREADS:-4} --access-logfile - --keyfile /certs/server.key --certfile /certs/server.cert run_pgadmin:app
else
    exec gunicorn --bind 0.0.0.0:8080 -w 1 --threads ${GUNICORN_THREADS:-4} --access-logfile - run_pgadmin:app
fi

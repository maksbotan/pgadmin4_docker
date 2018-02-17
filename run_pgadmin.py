import os, sys
from logging import getLogger, NullHandler

import builtins
builtins.SERVER_MODE = True

from waitress import serve

if __name__ == '__main__':
    email = os.environ.get('PGADMIN_SETUP_EMAIL', '')
    password = os.environ.get('PGADMIN_SETUP_PASSWORD', '')
    if not email or not password:
        print('You must specify PGADMIN_SETUP_EMAIL and PGADMIN_SETUP_PASSWORD env vars')
        sys.exit(1)

    threads = os.environ.get('PGADMIN_WAITRESS_THREADS', '')
    try:
        threads = int(threads)
    except:
        threads = 4

    from pgAdmin4 import app as application

    # Installing NullHandler on root logger prevents waitress from messing up logging with basicConfig()
    root_logger = getLogger()
    root_logger.addHandler(NullHandler())

    serve(application, host='0.0.0.0', port=8080, threads=threads)

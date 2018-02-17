module=$1
if [[ -z ${module} ]]; then
    echo 'Specify module'
    exit 1
fi

set -ex

mkdir -p wheels tars

pip download ${module}
tar xf ${module}-*
cd ${module}-*

if ! grep -q 'setuptools' setup.py; then
    # If setup script does not use setuptools, bdist_wheel will fail
    # Importing setuptools monkey patches something and fixes this
    sed -e '1 a\
from setuptools import setup' -i setup.py
fi

python setup.py bdist_wheel
cp -v dist/${module}-*.whl ../wheels

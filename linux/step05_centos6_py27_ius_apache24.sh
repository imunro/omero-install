#!/bin/bash

#start-copy
cp setup_omero_apache24.sh ~omero
#end-copy

#start-install
#install httpd 2.4
yum -y install httpd24u

virtualenv -p /usr/bin/python2.7 /home/omero/omeroenv
set +u
source /home/omero/omeroenv/bin/activate
set -u

# cannot use python27-mod_wsgi from ius since httpd2.2 is a dependency
# install via pip.
/home/omero/omeroenv/bin/pip2.7 install mod_wsgi-httpd
/home/omero/omeroenv/bin/pip2.7 install mod_wsgi

# Install OMERO.web requirements
/home/omero/omeroenv/bin/pip2.7 install -r ~omero/OMERO.server/share/web/requirements-py27-apache.txt
deactivate

#start-setup-as-omero
# See setup_omero_apache.sh for the apache config file creation
su - omero -c "bash -eux setup_omero_apache24.sh"
#end-setup-as-omero

# Add virtual env python to the python-path parameter of the WSGIDaemonProcess directive
sed -i 's/\(python-path\=\)/\1\/home\/omero\/omeroenv\/lib64\/python2.7\/site-packages:/' ~omero/OMERO.server/apache.conf.tmp

cp ~omero/OMERO.server/apache.conf.tmp /etc/httpd/conf.d/omero-web.conf

# create wsgi.conf file
cat << EOF > /etc/httpd/conf.d/wsgi.conf
LoadModule wsgi_module /home/omero/omeroenv/lib64/python2.7/site-packages/mod_wsgi/server/mod_wsgi-py27.so
EOF

chkconfig httpd on
service httpd start
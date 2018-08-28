FROM centos:7
RUN yum install -y epel-release && \
    yum clean all
RUN yum install -y curl gcc memcached rsync sqlite xfsprogs git-core \
                 libffi-devel xinetd liberasurecode-devel \
                 openssl-devel python-setuptools \
                 python-coverage python-devel python-nose \
                 pyxattr python-eventlet \
                 python-greenlet python-paste-deploy \
                 python-netifaces python-pip python-dns \
                 python-mock && \
                yum clean all
RUN pip install --upgrade pip setuptools pytz simplejson

# Build liberasurecode from source and install.
RUN yum install -y make autoconf automake libtool && \
    curl -L -s https://github.com/openstack/liberasurecode/archive/1.5.0.tar.gz | tar xvz -C /tmp && \
    cd /tmp/liberasurecode-1.5.0 && \
    ./autogen.sh && ./configure && make && make test && make install && \
    rm -rf /tmp/liberasurecode-1.5.0 && \
    yum autoremove -y make autoconf automake libtool && \
    yum clean all && \
    echo /usr/local/lib > /etc/ld.so.conf.d/usr-local-lib.conf && \
    ldconfig

# Download swift sources.
RUN yum install -y git-core && \
    git clone --branch 3.5.0 --single-branch --depth 1 https://github.com/openstack/python-swiftclient.git /usr/local/src/python-swiftclient && \
    cd /usr/local/src/python-swiftclient && python setup.py develop && \
    git clone --branch 2.17.0 --single-branch --depth 1 https://github.com/openstack/swift.git /usr/local/src/swift && \
    cd /usr/local/src/swift && python setup.py develop && \
    git clone --branch 1.12 --single-branch --depth 1 https://github.com/openstack/swift3.git /usr/local/src/swift3 && \
    cd /usr/local/src/swift3 && python setup.py develop && \
    yum autoremove -y git-core git && \
    yum clean all

# Install supervisord and create swift user.
RUN pip install supervisor==3.3.4 supervisor-stdout==0.1.1 && \
    mkdir /var/log/supervisor/ && \
    /usr/sbin/useradd -m -d /etc/swift -U swift && \
    mkdir -p /etc/swift && chown -R swift:swift /etc/swift && \
    mkdir -p /var/cache/swift  && chown -R swift:swift /var/cache/swift

# Add configuration files.
ADD files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD files/dispersion.conf /etc/swift/dispersion.conf
ADD files/rsyncd.conf /etc/rsyncd.conf
ADD files/swift.conf /etc/swift/swift.conf
ADD files/proxy-server.conf /etc/swift/proxy-server.conf
ADD files/account-server.conf /etc/swift/account-server.conf
ADD files/object-server.conf /etc/swift/object-server.conf
ADD files/container-server.conf /etc/swift/container-server.conf
ADD files/startmain.sh /usr/local/bin/startmain.sh
RUN chmod 755 /usr/local/bin/startmain.sh

EXPOSE 8080

CMD /usr/local/bin/startmain.sh

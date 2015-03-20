# ========================================================================
#
# ganbarodigital/docker-realtime-metrics
#
# A Graphite / statsd instance for collecting realtime metrics from your
# app and environment.
#
# See http://ganbarodigital.com/w/realtime-metrics-with-graphite
# See http://blog.stuartherbert.com/php/2011/09/21/real-time-graphing-with-graphite/
#
# ------------------------------------------------------------------------

FROM     ubuntu:14.04.1

# ========================================================================
#
# Versions
#
# Edit if you want to change which versions we install
#
# ------------------------------------------------------------------------

ENV elasticsearch_version 1.3.2
ENV etsy_version 0.7.2
ENV grafana_version 1.9.1
ENV graphite_version 0.9.x
ENV nodejs_version 0.12.0

# ========================================================================
#
# Image setup
#
# ------------------------------------------------------------------------

RUN     apt-get -y install software-properties-common
RUN     apt-get -y update
RUN     apt-get -y install build-essential git wget curl python-dev

# Pre-req for installing source code
RUN     mkdir ~/src

# ========================================================================
#
# Supervisor
#
# Install this first so that there's somewhere to drop config files into
#
# ------------------------------------------------------------------------

RUN apt-get -y install supervisor
ADD ./files/etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ========================================================================
#
# HTTP frontend
#
# ------------------------------------------------------------------------

# Install
RUN     apt-get -y install nginx

# Config files
ADD     ./files/etc/nginx/nginx.conf /etc/nginx/nginx.conf

# Startup scripts
ADD     ./files/etc/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf

# Ports
EXPOSE 80

# ========================================================================
#
# NodeJS
#
# Needed for etsy's statsd
#
# ------------------------------------------------------------------------

# Install
RUN     cd ~/src \
        && wget http://nodejs.org/dist/v0.12.0/node-v${nodejs_version}.tar.gz \
        && tar -zxf node-v${nodejs_version}.tar.gz \
        && cd node-v${nodejs_version} \
        && ./configure \
        && make install

# ========================================================================
#
# Statsd
#
# ------------------------------------------------------------------------

# Install statsd into /opt
RUN     cd ~/src \
        && git clone https://github.com/etsy/statsd.git \
        && cd statsd \
        && git checkout v${etsy_version} \
        && mkdir /opt/statsd \
        && cp -r * /opt/statsd

# Install statsd config file
ADD ./files/opt/statsd/config.js /opt/statsd/config.js

# Startup scripts
ADD ./files/etc/supervisor/conf.d/statsd.conf /etc/supervisor/conf.d/statsd.conf

# StatsD UDP port
EXPOSE  8125/udp

# StatsD Management port
EXPOSE  8126

# ========================================================================
#
# Graphite
#
# ------------------------------------------------------------------------

# Dependencies
RUN     apt-get -y install python-django-tagging python-simplejson \
                           python-memcache python-ldap python-cairo \
                           python-pysqlite2 python-support python-pip \
                           gunicorn memcached

RUN     pip install Twisted==11.1.0
RUN     pip install Django==1.5

# Install Whisper, Carbon, and Graphite-web
RUN     cd ~/src \
        && git clone https://github.com/graphite-project/whisper.git \
        && cd whisper \
        && git checkout ${graphite_version} \
        && python setup.py install

RUN     cd ~/src \
        && git clone https://github.com/graphite-project/carbon.git \
        && cd carbon \
        && git checkout ${graphite_version} \
        && python setup.py install

RUN     cd ~/src \
        && git clone https://github.com/graphite-project/graphite-web.git \
        && cd graphite-web \
        && git checkout ${graphite_version} \
        && python setup.py install

# Realtime hack
RUN     sed -e 's|var interval = 60;|var interval = 1;|g' -i /opt/graphite/webapp/content/js/*.js

# Config files
ADD     ./files/opt/graphite/conf/carbon.conf /opt/graphite/conf/carbon.conf
ADD     ./files/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
ADD     ./files/opt/graphite/conf/storage-schemas.conf /opt/graphite/conf/storage-schemas.conf
RUN     mv /opt/graphite/conf/storage-aggregation.conf.example /opt/graphite/conf/storage-aggregation.conf

# 2nd state of setup after installing config files
RUN     mkdir -p /opt/graphite/storage/whisper
RUN     chown -R www-data:www-data /opt/graphite/storage
RUN     chmod 0775 /opt/graphite/storage /opt/graphite/storage/whisper
RUN     touch /opt/graphite/storage/graphite.db
RUN     chmod 0664 /opt/graphite/storage/graphite.db
RUN     cd /opt/graphite/webapp/graphite && python manage.py syncdb --noinput

# Startup scripts
ADD     ./files/etc/supervisor/conf.d/carbon-cache.conf /etc/supervisor/conf.d/carbon-cache.conf
ADD     ./files/etc/supervisor/conf.d/graphite-webapp.conf /etc/supervisor/conf.d/graphite-webapp.conf
ADD     ./files/etc/supervisor/conf.d/memcached.conf /etc/supervisor/conf.d/memcached.conf

# Network ports
EXPOSE 81

# ========================================================================
#
# ElasticSearch
#
# Needed for Grafara's dashboards
#
# ------------------------------------------------------------------------

# Dependencies
RUN     apt-get -y install openjdk-7-jre

# Install ElasticSearch
RUN     cd ~/src \
        && wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${elasticsearch_version}.deb \
        && dpkg -i elasticsearch-${elasticsearch_version}.deb

ADD     ./files/usr/local/bin/run_elasticsearch.sh /usr/local/bin/run_elasticsearch.sh
RUN     chmod 755 /usr/local/bin/run_elasticsearch.sh

# Startup files
ADD     ./files/etc/supervisor/conf.d/elasticsearch.conf /etc/supervisor/conf.d/elasticsearch.conf

# ========================================================================
#
# Grafana
#
# ------------------------------------------------------------------------

# Install Grafana into /opt
RUN     cd ~/src \
        && wget http://grafanarel.s3.amazonaws.com/grafana-${grafana_version}.tar.gz \
        && tar -zxf grafana-${grafana_version}.tar.gz \
        && cd grafana-${grafana_version} \
        && mkdir /opt/grafana \
        && cp -r * /opt/grafana

# Config files
ADD     ./files/opt/grafana/config.js /opt/grafana/config.js

# ========================================================================
#
# All done
#
# ------------------------------------------------------------------------

CMD     ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

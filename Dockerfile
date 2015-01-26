#Kibana

FROM ubuntu
 
RUN echo 'deb http://archive.ubuntu.com/ubuntu trusty main universe' > /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu trusty-updates universe' >> /etc/apt/sources.list && \
    apt-get update

#Prevent daemon start during install
RUN	echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d

RUN DEBIAN_FRONTEND=noninteractive apt-get clean
RUN DEBIAN_FRONTEND=noninteractive apt-get autoclean
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less nano ntp net-tools inetutils-ping curl git telnet

#Install Oracle Java 7
RUN echo 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main' > /etc/apt/sources.list.d/java.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java7-installer

#ElasticSearch
RUN wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.2.tar.gz && \
    tar xf elasticsearch-*.tar.gz && \
    rm elasticsearch-*.tar.gz && \
    mv elasticsearch-* elasticsearch && \
    elasticsearch/bin/plugin -install mobz/elasticsearch-head

#Kibana
RUN wget https://download.elasticsearch.org/kibana/kibana/kibana-3.0.1.tar.gz && \
    tar xf kibana-*.tar.gz && \
    rm kibana-*.tar.gz && \
    mv kibana-* kibana

#NGINX
RUN apt-get install -y nginx

#Logstash
RUN wget https://download.elasticsearch.org/logstash/logstash/logstash-1.4.2.tar.gz && \
	tar xf logstash-*.tar.gz && \
    rm logstash-*.tar.gz && \
    mv logstash-* logstash

RUN mkdir ./logstash/conf.d
    
#Configuration
ADD ./ /docker-elk
RUN cd /docker-elk && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.saved && \
    cp nginx.conf /etc/nginx/nginx.conf && \
    cp certs/logstash-forwarder.crt /logstash/logstash-forwarder.crt && \
    cp private/logstash-forwarder.key /logstash/logstash-forwarder.key && \
    cp logstash.conf /logstash/ && \
    cp elasticsearch.yml /elasticsearch/

#Supervisord
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor && \
	mkdir -p /var/log/supervisor
RUN cd /docker-elk && cp supervisord-kibana.conf /etc/supervisor/conf.d
CMD ["/usr/bin/supervisord", "-n"]

#48080=nginx, 9200=elasticsearch, 48021=logstash, 48022=lumberjack
EXPOSE 48080 9200 48021 48022

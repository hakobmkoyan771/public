FROM ubuntu:20.04

USER 0

#init.yaml
RUN apt update && apt install wget gpg -y
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list
RUN apt update && apt-get install apt-transport-https -y

#elasticsearch.yaml
RUN sysctl -w vm.max_map_count=262144

ARG version=""

RUN apt update && apt install apt-utils elasticsearch=$version -y

COPY ./configs/elasticsearch.yaml /etc/elasticsearch/

RUN chown root:elasticsearch /etc/elasticsearch/elasticsearch.yaml
RUN apt install systemctl -y
RUN systemctl daemon-reload
RUN systemctl enable elasticsearch
RUN systemctl start elasticsearch || true

#kibana.yaml
RUN apt install kibana=$version -y

COPY ./configs/kibana.yaml /etc/kibana/

RUN systemctl daemon-reload
RUN systemctl start kibana || true

#logstash.yaml
RUN apt-get update && apt-get install curl -y
RUN curl https://artifacts.elastic.co/downloads/logstash/logstash-$version-amd64.deb -o logstash.deb && apt install ./logstash.deb

COPY ./configs/logstash.yaml /etc/logstash/

RUN chown root:elasticsearch /etc/logstash/logstash.yaml

COPY ./configs/logstash_pipeline.conf /etc/logstash/conf.d/

RUN chown root:elasticsearch /etc/logstash/conf.d/logstash_pipeline.conf
RUN systemctl daemon-reload
RUN systemctl start logstash || true

#beats.yaml
RUN apt install metricbeat=$version -y

COPY ./configs/metricbeat.yaml /etc/metricbeat/

RUN chown root:root /etc/metricbeat/metricbeat.yaml
RUN systemctl start metricbeat || true

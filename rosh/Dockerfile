# DOCKER-VERSION 0.3.4
FROM        perl:latest
MAINTAINER  Sven Axel Mahler ickooch@gmail.com
ENV AWS_CONFIG_FILE /opt/rosh/data/aws/config
ENV AWS_SHARED_CREDENTIALS_FILE /opt/rosh/data/aws/credentials
ENV ROSH_LIBREALM /opt/rosh/realms

ARG GIT_USER
ARG GIT_TOKEN

RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm Carton
RUN apt update
RUN apt upgrade -y
RUN apt install -y python3-pip
RUN pip3 install awscli --upgrade

RUN git clone https://$GIT_USER:$GIT_TOKEN@github.com/ickooch/rosh.git
RUN cd rosh/rosh && carton install

WORKDIR rosh/rosh
CMD carton exec perl rosh.pl

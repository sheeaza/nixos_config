FROM bundle:latest

RUN  mkdir /tmp; chmod 1777 /tmp; rm /sbin/*

WORKDIR /home/max

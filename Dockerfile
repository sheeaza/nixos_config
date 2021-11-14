FROM bundle:latest

RUN  mkdir /tmp; chmod 1777 /tmp; rm /sbin/*;
COPY packages/nvim/coc-settings.json /home/max/.config/nvim/

WORKDIR /home/max

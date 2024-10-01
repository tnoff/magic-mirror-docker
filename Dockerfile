FROM node:22-bullseye

# Setup basics
RUN apt-get -y update && apt-get -y upgrade
RUN apt-get install -y git bash vim certbot

# Setup mirror
RUN mkdir -p /opt/mirror
RUN git clone https://github.com/MagicMirrorOrg/MagicMirror /opt/mirror/MagicMirror
RUN git clone https://github.com/tnoff/MMM-BartTimes.git /opt/mirror/MagicMirror/modules/MMM-BartTimes
RUN git clone https://github.com/jclarke0000/MMM-MyScoreboard.git /opt/mirror/MagicMirror/modules/MMM-MyScoreboard
WORKDIR /opt/mirror/MagicMirror
RUN npm install

# Setup startup script
COPY files/startup.sh /opt/mirror
RUN chmod +x /opt/mirror/startup.sh

CMD ["bash", "/opt/mirror/startup.sh"]
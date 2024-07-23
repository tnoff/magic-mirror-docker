FROM node:22-bullseye

# Setup basics
RUN apt-get -y update && apt-get -y upgrade
RUN apt-get install -y git

# Setup mirror
RUN mkdir -p /opt/mirror
RUN git clone https://github.com/MagicMirrorOrg/MagicMirror /opt/mirror
WORKDIR /opt/mirror/MagicMirror
RUN npm run install-mm

# Setup startup script
COPY files/startup.sh /opt/mirror
RUN chmod +x /opt/mirror/startup.sh

CMD ["bash", "/opt/mirror/startup.sh"]
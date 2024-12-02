FROM node:22-bullseye

# Setup basics
RUN apt-get -y update && apt-get -y upgrade
RUN apt-get install -y git bash vim certbot git python3-dev python3-virtualenv


COPY files/requirements.txt /tmp/requirements.txt
RUN virtualenv /opt/venv
RUN /opt/venv/bin/pip install -r /tmp/requirements.txt
RUN rm /tmp/requirements.txt

# Setup mirror
RUN mkdir -p /opt/mirror
RUN git clone https://github.com/MagicMirrorOrg/MagicMirror /opt/mirror/MagicMirror
RUN git clone https://github.com/tnoff/MMM-BartTimes.git /opt/mirror/MagicMirror/modules/MMM-BartTimes
RUN git clone https://github.com/darickc/MMM-BackgroundSlideshow.git /opt/mirror/MagicMirror/modules/MMM-BackgroundSlideshow
# Run install on custom modules
WORKDIR /opt/mirror/MagicMirror/modules/MMM-BartTimes
RUN npm install

# Run final install
WORKDIR /opt/mirror/MagicMirror
RUN npm install

# Setup startup script
COPY files/startup.sh /opt/mirror
RUN chmod +x /opt/mirror/startup.sh

CMD ["bash", "/opt/mirror/startup.sh"]

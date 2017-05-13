# Dockerfile for docker-silk-flowviewer
# SiLK from cert.org is a netflow/sFlow/ipfix collector
# FlowViewer from NASA is a web-based graphical display program

FROM ubuntu:trusty
MAINTAINER Andy Freeland <andy.freeland@redjack.com>
MAINTAINER Rich Brown <richb.hanover@gmail.com>

# Current versions as of March 2017
ENV LIBFIXBUF_VERSION 1.7.1
ENV SILK_VERSION 3.15.0
ENV RRD_TOOL 1.6.0
ENV FLOWVIEWER 4.6.1

# Other environmental variables
ENV RRD_PATH /opt/rrdtool
ENV TERM ansi

ENV USERACCT flowviewer

# ---------------------------
# Work as user USERACCT, not root

RUN useradd -ms /bin/bash $USERACCT \
    && echo "$USERACCT ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERACCT \
    && chmod 0440 /etc/sudoers.d/$USERACCT \
    && ls /etc/sudoers.d \
    && cat /etc/sudoers.d/README

USER $USERACCT
ENV USERHOME /home/$USERACCT
WORKDIR $USERHOME

# ========= Installing Dependencies ==============
# Install libfixbuf and SiLK dependencies
RUN sudo apt-get update && sudo apt-get -y install \
    apache2 \
    apt-utils \
    bison \
    build-essential \
    cpanminus \
    curl \
    expat \
    flex \
    groff \
    libc-ares-dev \
    libdbi-perl \
    libexpat-dev \
    libgd2-noxpm-dev \
    libglib2.0-dev \
    libgnutls-dev \
    liblzo2-dev \
    libpango1.0-dev \
    libpcap0.8-dev \
    libpcre3-dev \
    libssl-dev \
    libxml2-dev \
    man \
    pkg-config \
    unzip \
    zlib1g 

# ============ Install SiLK &c ==============
# from http://flowbat.com

COPY scripts/silkonabox.sh $USERHOME

RUN ls -al \
    && sudo chown $USERACCT:$USERACCT silkonabox.sh \
    && chmod +x silkonabox.sh \
    && export TERM=ansi \
    && ./silkonabox.sh

# ============ Installing FlowViewer Dependencies =================

# Install GD - see https://hub.docker.com/r/genomicpariscentre/bioperl/~/dockerfile/
# See also: https://libgd.github.io/pages/faq.html

RUN cpanm GD \
 GD::Graph \
 GD::Text 

 # Download and install RDDTool
 # See: https://github.com/rickdesantis/docker-files/blob/master/rrdtool/Dockerfile
WORKDIR $USERHOME
RUN curl http://oss.oetiker.ch/rrdtool/pub/rrdtool-$RRD_TOOL.tar.gz -OL \
    && tar zxf rrdtool-$RRD_TOOL.tar.gz \
    && sudo mkdir -p $RRD_PATH \
    && cd rrdtool-$RRD_TOOL && ./configure --prefix=$RRD_PATH && make && sudo make install 

# ============ Installing FlowViewer =================
# Retrieve FlowViewer sources from richb github.com repo - version 4.6.1 reflects refactoring of files

WORKDIR /var/www

RUN    curl https://github.com/richb-hanover/FlowViewer/archive/master.zip -0L > /tmp/FlowViewer-master.zip \
    && unzip /tmp/FlowViewer-master.zip -d /tmp \
    && sudo rm -rf html  \
    && sudo mv /tmp/FlowViewer-master/html/ . \
    && sudo mv /tmp/FlowViewer-master/cgi-bin/ . \
    && sudo chown -R www-data: html/ \
    && sudo find html -type f -exec chmod 664 {} + -o -type d -exec chmod 775 {} + \
    && sudo chown -R www-data: cgi-bin \
    && sudo chmod -R +x cgi-bin 

# ==== Install the replacement VirtualHost file with +ExecCGI

COPY scripts/000-default.conf /etc/apache2/sites-available/ 

# ==== Enable the cgi mod

RUN cd /etc/apache2/mods-enabled \
  && sudo ln -s ../mods-available/cgi.load

# ==== Start Apache2 when starting the image

# Use docker run -d -p 8080:80 -p 2055:2055 flowviewer-silk 

# not...
# CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
# ENTRYPOINT ["service", "apache2", "start"]
# CMD service apache2 start && tail -F /var/log/apache2/error.log

WORKDIR $USERHOME
COPY scripts/startup.sh          startup.sh
COPY scripts/start_apache2.sh    start_apache2.sh
COPY scripts/start_rwflowpack.sh start_rwflowpack.sh
COPY scripts/start_yaf.sh        start_yaf.sh
RUN    sudo chmod +x startup.sh \
    && sudo chmod +x start_apache2.sh \
    && sudo chmod +x start_rwflowpack.sh \
    && sudo chmod +x start_yaf.sh 

EXPOSE 80
EXPOSE 2055

CMD ./startup.sh


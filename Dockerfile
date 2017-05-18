# Dockerfile for docker-silk-flowviewer
# SiLK from cert.org is a netflow/sFlow/ipfix collector
# FlowViewer from NASA is a web-based graphical display program

FROM ubuntu:trusty
MAINTAINER Andy Freeland <andy.freeland@redjack.com>
MAINTAINER Rich Brown <richb.hanover@gmail.com>

# Current versions as of May 2017
ENV SILK_VERSION 3.15.0
ENV LIBFIXBUF_VERSION 1.7.1
ENV YAF_VERSION 2.8.4
ENV RRD_TOOL 1.7.0
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
    checkinstall \
    cpanminus \
    curl \
    expat \
    flex \
    glib2.0 \
    groff \
    libc-ares-dev \
    libdbi-perl \
    libexpat-dev \
    libgd2-noxpm-dev \
    libglib2.0-dev \
    libgnutls-dev \
    liblzo2-dev \
    libpango1.0-dev \
    libpcap-dev \
    libpcre3-dev \
    libssl-dev \
    libxml2-dev \
    make \
    man \
    nano \
    pkg-config \
    python-dev \
    rrdtool \
    unzip \
    wget \
    zlib1g 

# ============ Installing FlowViewer Dependencies =================

# Install GD - see https://hub.docker.com/r/genomicpariscentre/bioperl/~/dockerfile/
# See also: https://libgd.github.io/pages/faq.html

RUN cpanm GD \
 GD::Graph \
 GD::Text 

# Download and install RDDTool
# See: https://github.com/rickdesantis/docker-files/blob/master/rrdtool/Dockerfile
# WORKDIR $USERHOME
# RUN curl http://oss.oetiker.ch/rrdtool/pub/rrdtool-$RRD_TOOL.tar.gz -OL \
#     && tar zxf rrdtool-$RRD_TOOL.tar.gz \
#     && sudo mkdir -p $RRD_PATH \
#     && cd rrdtool-$RRD_TOOL \
#     && ./configure --prefix=$RRD_PATH \
#     && make \
#     && sudo make install 

# ============ Install all the SiLK files ==============
# from https://tools.netsa.cert.org/confluence/pages/viewpage.action?pageId=23298051

RUN    cd ~ \
    && mkdir tmp \
    && cd tmp \
    && wget http://tools.netsa.cert.org/releases/silk-$SILK_VERSION.tar.gz \
    && wget http://tools.netsa.cert.org/releases/libfixbuf-$LIBFIXBUF_VERSION.tar.gz \
    && wget http://tools.netsa.cert.org/releases/yaf-$YAF_VERSION.tar.gz

# # ============ Install fixbuf ===============

RUN    cd ~/tmp \
    && tar -zxvf libfixbuf-$LIBFIXBUF_VERSION.tar.gz \
    && cd libfixbuf-$LIBFIXBUF_VERSION \
    && ./configure \
    && make \
    && sudo make install

# # ============ Install yaf ===============

RUN    cd ~/tmp \
    && tar -zxvf yaf-$YAF_VERSION.tar.gz \
    && cd yaf-$YAF_VERSION \
    && export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    && ./configure --enable-applabel \
    && make \
    && sudo make install

# ============ Make a directory for SiLK ===============

RUN sudo mkdir /data

# ============ Install SiLK ===============

RUN cd ~/tmp \
    && tar -xvzf silk-$SILK_VERSION.tar.gz \
    && cd silk-$SILK_VERSION \
    && ./configure \
        --with-libfixbuf=/usr/local/lib/pkgconfig/ \
        --with-python \
        --enable-ipv6 \
    && make \
    && sudo make install

# ============ Fix LD_CONFIG_PATH ===============

COPY scripts/ld_config_path.silk.conf /etc/ld.so.conf.d/

# ============ run ldconfig ===============

RUN sudo ldconfig

# ============ Copy silk.conf ===============

RUN    cd ~/tmp/silk-$SILK_VERSION \
    && sudo cp site/twoway/silk.conf /data

# ============ Copy sensors.conf ===============

COPY scripts/sensors.conf /data

# ============ Configure rwflowpack ===============

RUN cat /usr/local/share/silk/etc/rwflowpack.conf | \
        sed 's/ENABLED=/ENABLED=yes/;' | \
        sed 's/SENSOR_CONFIG=/SENSOR_CONFIG=\/data\/sensors.conf/;' | \
        sed 's/SITE_CONFIG=/SITE_CONFIG=\/data\/silk.conf/' | \
        sed 's/LOG_TYPE=syslog/LOG_TYPE=legacy/' | \
        sed 's/LOG_DIR=.*/LOG_DIR=\/var\/log/' | \
        sed 's/CREATE_DIRECTORIES=.*/CREATE_DIRECTORIES=yes/' \
        >> rwflowpack.conf \
    && sudo mv rwflowpack.conf /usr/local/etc/

# COPY scripts/silkonabox.sh $USERHOME# 

# RUN ls -al \
#     && sudo chown $USERACCT:$USERACCT silkonabox.sh \
#     && chmod +x silkonabox.sh \
#     && export TERM=ansi \
#     && ./silkonabox.sh

# ============ Installing FlowViewer files =================
# Retrieve FlowViewer sources from github.com/richb-hanover repo 
# Version 4.6.1 reflects refactoring of files

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

# ==== create startup.sh to invoke all the important long-running processes
#       Could switch to supervisord, as Docker folks encourage

WORKDIR $USERHOME
COPY scripts/startup.sh          startup.sh
COPY scripts/start_apache2.sh    start_apache2.sh
COPY scripts/start_rwflowpack.sh start_rwflowpack.sh
COPY scripts/start_yaf.sh        start_yaf.sh
COPY scripts/start_flowviewer.sh start_flowviewer.sh
RUN    sudo chmod +x startup.sh \
    && sudo chmod +x start_apache2.sh \
    && sudo chmod +x start_rwflowpack.sh \
    && sudo chmod +x start_yaf.sh \
    && sudo chmod +x start_flowviewer.sh

EXPOSE 80
EXPOSE 2055

CMD ./startup.sh


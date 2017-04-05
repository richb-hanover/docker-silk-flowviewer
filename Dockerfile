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
ENV USERHOME  /root
ENV RRD_PATH /opt/rrdtool

# ========= Installing Dependencies ==============
# Install libfixbuf and SiLK dependencies
RUN apt-get update && apt-get -y install \
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

# ========= Installing SiLK & libfixbuf ==============
# Download and build libfixbuf
RUN mkdir -p /src \
    && cd /src \
    && curl -f -L -O https://tools.netsa.cert.org/releases/libfixbuf-$LIBFIXBUF_VERSION.tar.gz \
    && tar zxf libfixbuf-$LIBFIXBUF_VERSION.tar.gz \
    && cd /src/libfixbuf-$LIBFIXBUF_VERSION \
    && ./configure --with-openssl \
    && make \
    && make install \
    && rm -rf /src

# Download and build SiLK
RUN mkdir -p /src \
    && cd /src \
    && curl -f -L -O https://tools.netsa.cert.org/releases/silk-$SILK_VERSION.tar.gz \
    && tar zxf silk-$SILK_VERSION.tar.gz \
    && cd /src/silk-$SILK_VERSION \
    && ./configure --enable-ipv6 \
    && make \
    && make install \
    && rm -rf /src

RUN ldconfig

# ============ Installing FlowViewer Dependencies =================

# Install GD - see https://hub.docker.com/r/genomicpariscentre/bioperl/~/dockerfile/
# See also: https://libgd.github.io/pages/faq.html

RUN cpanm GD \
 GD::Graph \
 GD::Text 

 # Download and install RDDTool
 # See: https://github.com/rickdesantis/docker-files/blob/master/rrdtool/Dockerfile
WORKDIR $USERHOME
RUN curl http://oss.oetiker.ch/rrdtool/pub/rrdtool-$RRD_TOOL.tar.gz -OL && \
    tar zxf rrdtool-$RRD_TOOL.tar.gz && \
    mkdir -p $RRD_PATH && \
    cd rrdtool-$RRD_TOOL && ./configure --prefix=$RRD_PATH && make && make install 

# ============ Installing FlowViewer =================
# Retrieve FlowViewer sources from richb github.com repo - version 4.6.1 reflects refactoring of files

WORKDIR /var/www

RUN curl https://github.com/richb-hanover/FlowViewer/archive/master.zip -0L > /tmp/FlowViewer-master.zip && \
    unzip /tmp/FlowViewer-master.zip -d /tmp && \
    rm -rf html && \
    mv /tmp/FlowViewer-master/html/ . && \
    mv /tmp/FlowViewer-master/cgi-bin/ . && \
    chown -R www-data: html/ && \
    find html -type f -exec chmod 664 {} + -o -type d -exec chmod 775 {} + && \
    chown -R www-data: cgi-bin && \
    chmod -R +x cgi-bin 

# ==== Install the replacement VirtualHost file with +ExecCGI

COPY 000-default.conf /etc/apache2/sites-available/ 

# ==== Enable the cgi mod

RUN cd /etc/apache2/mods-enabled && \
    ln -s ../mods-available/cgi.load

# ==== Start Apache2 when starting the image

# Use docker run -d -p 80:80 docker-silk /usr/sbin/apache2ctl -D FOREGROUND 

# not...
# ENTRYPOINT ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
# ENTRYPOINT ["service", "apache2", "start"]
# CMD service apache2 start && tail -F /var/log/apache2/error.log


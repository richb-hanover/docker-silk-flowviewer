# docker-silk

[![Build Status](https://img.shields.io/travis/redjack/docker-silk/master.svg)](https://travis-ci.org/redjack/docker-silk)

Docker image containing SiLK and libfixbuf cloned from https://github.com/redjack/docker-silk
  Updated to load SiLK 3.15.0 and (retain) libfixbuf 1.7.1

Added code to install FlowViewer from https://sourceforge.net/p/flowviewer/wiki/Home/

## To build the Docker instance

```
docker build -t silk-flowviewer .
```

## To run it and/or look around:

```
docker run -d silk-flowviewer
docker ps # to get container name
docker exec -i -t <container-name> /bin/bash
```
References:


FlowViewer 4.6 tar: https://superb-sea2.dl.sourceforge.net/project/flowviewer/FlowViewer_4.6.tar
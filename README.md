# docker-silk-flowviewer

[![Build Status](https://img.shields.io/travis/redjack/docker-silk/master.svg)](https://travis-ci.org/redjack/docker-silk)

Docker image containing SiLK and libfixbuf cloned from https://github.com/redjack/docker-silk
  Updated to load SiLK 3.15.0 and (retain) libfixbuf 1.7.1

Added code to install FlowViewer from https://sourceforge.net/p/flowviewer/wiki/Home/

## To build the Docker instance

```
docker build -t flowviewer_silk .
```

## To run it and/or look around:

(This starts web server on external port 81; receives flow exports on port 22055)

```
docker run -d -p 82:80 -p 22055:2055 --name flowviewer_silk flowviewer_silk 
docker exec -i -t flowviewer_silk /bin/bash
```

To stop the container and remove its name

```
docker rm -f flowviewer_silk
```

Then go to http://localhost:82/, and get redirected






ARG CODE_VERSION=16.04

FROM ubuntu:${CODE_VERSION}

RUN apt-get update && apt-get install -y curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /home/Codes

ENV USER erinaldo-souza
ENV SHELL /bin/bash
ENV LOGNAME Erinaldo Souza

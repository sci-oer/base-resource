
FROM alpine:latest AS wikijs
ARG WIKI_VERSION=v2.5.297

# install wikijs
RUN wget https://github.com/Requarks/wiki/releases/download/${WIKI_VERSION}/wiki-js.tar.gz -O /tmp/wiki-js.tar.gz && \
    mkdir -p /opt/wiki/sideload && \
    tar xzf /tmp/wiki-js.tar.gz -C /opt/wiki && \
    rm /tmp/wiki-js.tar.gz

COPY configs/wiki_config.yml /opt/wiki/config.yml
COPY database.sqlite /opt/wiki/database.sqlite

# add the sideload files
ADD https://raw.githubusercontent.com/Requarks/wiki-localization/master/en.json /opt/wiki/sideload/
ADD https://raw.githubusercontent.com/Requarks/wiki-localization/master/locales.json /opt/wiki/sideload/



FROM ubuntu:focal

LABEL org.opencontainers.version="v1.0.0"

LABEL org.opencontainers.image.authors="Marshall Asch <masch@uoguelph.ca> (https://marshallasch.ca)"
LABEL org.opencontainers.image.source="https://github.com/sci-oer/base-resources.git"
LABEL org.opencontainers.image.vendor="sci-oer"
LABEL org.opencontainers.image.licenses="GPL-3.0-only"
LABEL org.opencontainers.image.title="Offline Course Resouce"
LABEL org.opencontainers.image.description="This image is a base that can be used to act as an offline resource for students to contain all the instructional matrial and tools needed to do the course content"
LABEL org.opencontainers.image.base.name="registry-1.docker.io/ubuntu:focal"


ENV DEBIAN_FRONTEND=noninteractive  \
    TERM=xterm-256color \
    UID=1000 \
    UNAME=student

WORKDIR /course
VOLUME [ "/course" ]
ENTRYPOINT [ "/scripts/entrypoint.sh" ]

EXPOSE 3000
EXPOSE 8000
EXPOSE 8888
EXPOSE 22

HEALTHCHECK --start-period=20s --interval=30s --timeout=3s CMD /scripts/healthcheck.sh

# create a 'normal' user so everything does not need to be run as root
RUN useradd -m -s /bin/bash -u "${UID}" "${UNAME}" && \
    echo "${UNAME}:password" | chpasswd

# setup static directories
RUN mkdir -p \
        /builtin/jupyter \
        /builtin/coursework \
        /opt/static/lectures  \
        /builtin/practiceProblems && \
    ln -s /course /home/${UNAME}/course && \
    chown -R ${UID}:${UID} /builtin /course

RUN echo 'export PS1="\[\033[01;32m\]oer\[\033[00m\]-\[\033[01;34m\]\W\[\033[00m\]\$ "' >> /home/${UNAME}/.bashrc
# setup the man pages
# RUN yes | unminimize

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl \
    git \
    vim \
    nano \
    openssh-server \
    unzip \
    gcc \
    g++ \
    make \
    build-essential \
    sqlite3 \
    python3-dev \
    pip \
    sudo \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    locales \
&& rm -rf /var/lib/apt/lists/*

# generate and use UTF-8 locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN echo "${UNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${UNAME} && \
    chmod 0440 /etc/sudoers.d/${UNAME}

# install node
ARG NODE_VERSION=16
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm

COPY --from=wikijs --chown=${UID}:${UID} /opt/wiki /opt/wiki/
RUN cd /opt/wiki && npm rebuild sqlite3

# install jupyter dependancies
COPY ./requirements.txt requirements.txt
RUN pip3 install -r requirements.txt && rm requirements.txt

# Install jupyter kernerls
RUN beakerx install

COPY configs/jupyter_lab_config.py /opt/jupyter/jupyter_lab_config.py

COPY --chown=${UID}:${UID} scripts motd.txt /scripts/

USER ${UNAME}

# these three labels will change every time the container is built
# put them at the end because of layer caching
ARG VERSION=v1.0.0
LABEL org.opencontainers.image.version="$VERSION"

ARG VCS_REF
LABEL org.opencontainers.image.revision="${VCS_REF}"

ARG BUILD_DATE
LABEL org.opencontainers.image.created="${BUILD_DATE}"

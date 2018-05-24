FROM ubuntu:18.04
MAINTAINER David Bernheisel <david@bernheisel.com>

## Setup Environment
WORKDIR /app
RUN apt-get update && apt-get install -y \
  curl locales aptitude git wget build-essential automake \
  autoconf m4 nginx
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TERM=linux

## Install language and its dependencies

# OPTION 1: Use asdf for all version management.
# Benefit: One place (.tool-versions) to manage versions
# Drawback: It's slower
RUN apt-get update
RUN apt-get install -y \
  libreadline-dev libyaml-dev libncurses5-dev ca-certificates \
  libssh-dev libxslt-dev xsltproc libxml2-utils libffi-dev \
  libtool unzip \
  default-jdk unixodbc-dev fop \
  libwxgtk3.0-dev libgl1-mesa-dev libglu1-mesa-dev
# OPTION 2: Install versions directly. Comment out if you want asdf
# to install versions.
# Benefit: It's faster
# Drawback: Two places to manage versions
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
  dpkg -i erlang-solutions_1.0_all.deb && \
  apt-get update && \
  apt-get install -y \
    esl-erlang=1:20.3


## Install asdf
# bin/setup will use asdf to install versions, but won't
# try if they're already installed.
RUN git clone https://github.com/asdf-vm/asdf.git /asdf
RUN echo '. /asdf/asdf.sh' >> /etc/bash.bashrc
ENV PATH /asdf/bin:/asdf/shims:$PATH
ENV NODEJS_CHECK_SIGNATURES=no
RUN asdf plugin-add erlang && \
    asdf plugin-add elixir && \
    asdf plugin-add nodejs

# Application dependencies. There's usually a dependency for python for
# building phoenix assets.
RUN apt-get install -y \
  python

# Build the elixir app
ENV MIX_ENV prod
COPY . /app
RUN ./bin/setup prod

CMD ["/bin/sh"]

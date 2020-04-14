FROM elixir:1.10.2
MAINTAINER Henry Firth

# Make sure we have sudo
RUN apt-get update \
    && apt-get -y install sudo \
    && apt-get -y install curl \
    && apt-get -y install apt-utils \
    && apt-get -y install inotify-tools

# Create an app directory to store our files in
ADD . /app

# Install Hex
RUN mix local.hex --force \
    && mix local.rebar --force

WORKDIR /app
CMD ["/bin/bash"]

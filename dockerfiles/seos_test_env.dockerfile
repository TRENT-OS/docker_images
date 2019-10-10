FROM ubuntu
MAINTAINER Carmelo carmelo.pintaudi@hensoldt-cyber.com

ARG USER_NAME
ARG USER_ID

RUN apt-get update

# install build tools
RUN apt-get install -y git build-essential cmake ninja-build

# install python venv and pytest
RUN apt-get install -y python3-venv python3-pytest

# install qemu and netcat
RUN apt-get install -y qemu-system-arm netcat

# install unit tests tools
RUN apt-get install -y lcov libgtest-dev
RUN cd /usr/src/gtest && cmake CMakeLists.txt && make && cp *.a /usr/lib

# add the user
RUN useradd -u $USER_ID $USER_NAME


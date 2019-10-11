FROM ubuntu
MAINTAINER Carmelo carmelo.pintaudi@hensoldt-cyber.com

ARG USER_NAME
ARG USER_ID

RUN apt-get update

# install build tools
RUN apt-get install -y git build-essential cmake ninja-build

# install python venv and pytest
RUN apt-get install -y python3-venv python3-pytest python3-pip

# install python requirements for tests
RUN pip3 install pytest-repeat

# install qemu and netcat
RUN apt-get install -y qemu-system-arm

# install unit tests tools
RUN apt-get install -y lcov libgtest-dev
RUN cd /usr/src/gtest && cmake CMakeLists.txt && make && cp *.a /usr/lib

# install dependecies for the tools
RUN apt-get install -y netcat libvdeplug-dev

# add the user
RUN useradd -u $USER_ID $USER_NAME


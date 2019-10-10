FROM ubuntu
MAINTAINER Carmelo carmelo.pintaudi@hensoldt-cyber.com

RUN apt-get update && apt-get upgrade -y

# add the jenkins user with UID 1000
RUN useradd jenkins

# install tools
RUN apt-get install -y git build-essential cmake ninja-build

# install python venv and pytest
RUN apt-get install -y python3-venv python3-pytest

# install qemu and netcat
RUN apt-get install -y qemu-system-arm netcat




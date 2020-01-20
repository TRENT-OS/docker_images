FROM ubuntu
MAINTAINER Carmelo carmelo.pintaudi@hensoldt-cyber.com

ARG USER_NAME
ARG USER_ID

# crate the user
RUN useradd -u ${USER_ID} ${USER_NAME} -d /home/${USER_NAME} \
    && mkdir /home/${USER_NAME} \
    && adduser ${USER_NAME} sudo \
    && passwd -d ${USER_NAME} \
    && chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME} \
    && chmod -R ug+rw /home/${USER_NAME}

# update package list
RUN apt-get update

# install riscv gdb
RUN apt-get install -y gdc-riscv64-linux-gnu

# install ddd
RUN apt-get install -y ddd

# cleanup
RUN apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/


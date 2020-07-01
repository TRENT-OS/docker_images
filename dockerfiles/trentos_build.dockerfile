FROM trustworthysystems/camkes-riscv

LABEL ORGANISATION="Hensoldt Cyber"
LABEL MAINTAINER1="Carmelo carmelo.pintaudi@hensoldt-cyber.com"
LABEL MAINTAINER2="Thomas thomas.boehm@hensoldt-cyber.com"

ARG USER_NAME
ARG USER_ID
ARG SCRIPT=trentos_build_env.sh

COPY *.sh /tmp/

RUN /bin/bash /tmp/${SCRIPT} ${USER_ID} ${USER_NAME}
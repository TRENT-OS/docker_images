FROM ubuntu:focal

LABEL ORGANISATION="Hensoldt Cyber"
LABEL MAINTAINER1="Carmelo carmelo.pintaudi@hensoldt-cyber.com"
LABEL MAINTAINER2="Thomas thomas.boehm@hensoldt-cyber.com"

ARG USER_NAME
ARG USER_ID
ARG SCRIPT=trentos_test_env.sh
ARG ENTRYPOINT_SCRIPT=test_entrypoint.sh

COPY *.sh /tmp/

RUN /bin/bash /tmp/${SCRIPT} ${USER_ID} ${USER_NAME}

COPY demo_iot_mosquitto_config/mosquitto /etc/mosquitto

COPY nginx/default /etc/nginx/sites-enabled

RUN chmod +x /tmp/${ENTRYPOINT_SCRIPT}

RUN mv /tmp/${ENTRYPOINT_SCRIPT} /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

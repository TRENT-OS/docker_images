FROM ubuntu:focal

LABEL MAINTAINER="info@hensoldt-cyber.com"
LABEL ORGANISATION="HENSOLDT Cyber GmbH"

ARG USER_NAME
ARG USER_ID
ARG SCRIPT=test_env.sh
ARG ENTRYPOINT_SCRIPT=entrypoint.sh

COPY *.sh /tmp/

RUN /bin/bash /tmp/${SCRIPT} ${USER_ID} ${USER_NAME}

COPY demo_iot_mosquitto_config/mosquitto /etc/mosquitto

COPY nginx/default /etc/nginx/sites-enabled

RUN chmod +x /tmp/${ENTRYPOINT_SCRIPT}

RUN mv /tmp/${ENTRYPOINT_SCRIPT} /entrypoint.sh

USER ${USER_NAME}:${USER_NAME}

ENTRYPOINT ["/entrypoint.sh"]

CMD ["bash"]

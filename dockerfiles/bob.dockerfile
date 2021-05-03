FROM ubuntu:focal

LABEL ORGANISATION="Hensoldt Cyber"
LABEL MAINTAINER="Thomas thomas.boehm@hensoldt-cyber.com"

ARG USER_NAME
ARG USER_ID

ARG SCRIPT=bob.sh
ARG ENTRYPOINT_SCRIPT=entrypoint.sh

COPY ${SCRIPT} /tmp/

COPY ${ENTRYPOINT_SCRIPT} /tmp/

RUN /bin/bash /tmp/${SCRIPT} ${USER_ID} ${USER_NAME}

RUN chmod +x /tmp/${ENTRYPOINT_SCRIPT}

RUN mv /tmp/${ENTRYPOINT_SCRIPT} /entrypoint.sh

USER ${USER_NAME}:${USER_NAME}

ENTRYPOINT ["/entrypoint.sh"]

CMD ["bash"]


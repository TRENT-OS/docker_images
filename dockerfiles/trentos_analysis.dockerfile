FROM trentos_build:20210503

LABEL ORGANISATION="HENSOLDT Cyber"
LABEL MAINTAINER1="Franz franz.schauer@hensoldt-cyber.de"
LABEL MAINTAINER2="Thomas thomas.boehm@hensoldt-cyber.de"

ARG USER_NAME
ARG USER_ID
ARG SCRIPT=analysis_env.sh
ARG ENTRYPOINT_SCRIPT=entrypoint.sh

USER root:root

COPY *.sh /tmp/

RUN /bin/bash /tmp/${SCRIPT} ${USER_ID} ${USER_NAME}

RUN chmod +x /tmp/${ENTRYPOINT_SCRIPT}

RUN mv /tmp/${ENTRYPOINT_SCRIPT} /entrypoint.sh

USER ${USER_NAME}:${USER_NAME}

ENTRYPOINT ["/entrypoint.sh"]

CMD ["bash"]

FROM trentos_build:20210503

LABEL ORGANISATION="HENSOLDT Cyber"
LABEL MAINTAINER1="Franz franz.schauer@hensoldt-cyber.de"
LABEL MAINTAINER2="Thomas thomas.boehm@hensoldt-cyber.de"

ARG USER_NAME
ARG USER_ID
ARG SCRIPT=analysis_env.sh
ARG ENTRYPOINT_SCRIPT=entrypoint.sh
ARG DASHBOARD_CONFIG_DIR=/home/${USER_NAME}/axivion-dashboard/config/

# root (base container already switched to user)

USER root:root

COPY *.sh /tmp/

COPY --chown=${USER_NAME} axivion_suite/dashboard* ${DASHBOARD_CONFIG_DIR}
COPY --chown=${USER_NAME} axivion_suite/*.key /home/${USER_NAME}/.bauhaus/

COPY --chown=${USER_NAME} .ssh/id_rsa* /home/${USER_NAME}/.ssh/
COPY --chown=${USER_NAME} .ssh/known_hosts /home/${USER_NAME}/.ssh/

RUN /bin/bash /tmp/${SCRIPT} ${USER_NAME} ${DASHBOARD_CONFIG_DIR}

RUN chmod +x /tmp/${ENTRYPOINT_SCRIPT}

RUN mv /tmp/${ENTRYPOINT_SCRIPT} /entrypoint.sh

# user

USER ${USER_NAME}:${USER_NAME}

# remove group-read permission of private key
RUN chmod -R 600 /home/${USER_NAME}/.ssh/id_rsa

ENTRYPOINT ["/entrypoint.sh"]

CMD ["bash"]

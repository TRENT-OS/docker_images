FROM trustworthysystems/camkes
MAINTAINER Carmelo carmelo.pintaudi@hensoldt-cyber.com

ARG USER_NAME
ARG USER_ID

# crate the user
RUN useradd -u ${USER_ID} ${USER_NAME} -d /home/${USER_NAME} \
    && mkdir /home/${USER_NAME} \
    && adduser ${USER_NAME} sudo \
    && passwd -d ${USER_NAME} \
    && echo 'export PATH=/scripts/repo:$PATH' >> /home/${USER_NAME}/.bashrc \
    && chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME} \
    && chmod -R ug+rw /home/${USER_NAME}

# let the user use the Haskell stack pre-installed for root
RUN echo "allow-different-user: true" >> /root/.stack/config.yaml \
    && groupadd stack \
    && usermod -a -G stack ${USER_NAME} \
    && chmod a+x /root && chgrp -R stack /root/.stack \
    && chmod -R g=u /root/.stack \
    && cd /home/${USER_NAME} \
    && ln -s /root/.stack

# update package list
RUN apt-get update

# install code style checkers
RUN apt-get install -y astyle

# install code statical analysis tools
RUN apt-get install -y cppcheck clang-tidy

# install documentation tools
RUN apt-get install -y doxygen graphviz

# cleanup
RUN apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/


FROM trustworthysystems/camkes
MAINTAINER Carmelo carmelo.pintaudi@hensoldt-cyber.com

ARG USER_NAME
ARG USER_ID

RUN apt-get update

# install code style checkers
RUN apt-get install -y astyle

# install code statical analysis tools
RUN apt-get install -y cppcheck clang-tidy

# install documentation tools
RUN apt-get install -y doxygen graphviz

# add the user
RUN useradd -u $USER_ID $USER_NAME

# README

The RSA key pair is used by the TRENTOS analysis docker container to authorize
the following remote logins:
- filestorageuser @ hc-axiviondashboard
- git @ git-server

The key pair is placed in the `/home/user/.ssh` directory together with the
known hosts. The public keys are pre-installed on the servers.

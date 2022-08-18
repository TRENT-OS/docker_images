#!/bin/bash -ue

USER_ID="$1"
USER_NAME="$2"

# install fixuid to fix the runtime UID/GID problem in the container entrypoint script
wget https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-amd64.tar.gz -O /tmp/fixuid.gz
if ! echo "caa7e0e4c88e1b154586a46c2edde75a23f9af4b5526bb11626e924204585050 /tmp/fixuid.gz" | sha256sum -c -; then
     echo "Hash failed"
     exit 1
fi

mkdir -p /tmp/fixuid
tar -xzf /tmp/fixuid.gz -C /tmp/fixuid
rm /tmp/fixuid.gz

# install fixuid with proper attributes
cp -v /tmp/fixuid/fixuid /usr/local/bin/
rm -r /tmp/fixuid
chown root:root /usr/local/bin/fixuid
chmod 4755 //usr/local/bin/fixuid

# create config file
mkdir -p /etc/fixuid
cat << EOF > /etc/fixuid/config.yml
user: ${USER_NAME}
group: ${USER_NAME}
paths:
- /home/${USER_NAME}
- /tmp
EOF

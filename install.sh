#!/usr/bin/env bash

set -e

: ${STEPPATH:=$HOME/.step}

mkdir -p ${STEPPATH}/plugins/
install -m 0755 plugins/bash/* ${STEPPATH}/plugins/

echo
echo "The step plugins have now been installed. To get started run:"
echo
echo "Ensure you have an ssh-agent running."
echo "https://www.cyberciti.biz/faq/how-to-use-ssh-agent-for-authentication-on-linux-unix/"
echo "is a good source of information about that."
echo

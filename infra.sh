#!/bin/bash

set -o xtrace

PUBLIC_IP=$(terraform output public_ip | tr -d '"')
curl http://$PUBLIC_IP
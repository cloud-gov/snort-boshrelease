#!/bin/bash

set -e -u -x

/opt/pulledpork-0.7.0/pulledpork.pl \
  -c snort-release-source/ci/config/pulledpork.conf \
  -O $OINKCODE

cp -r snort-release-source snort-pulledpork-source

#!/bin/bash

set -e -u -x

DIR=$(pwd)

cd snort-release-source/ci/config/snort-conf

perl /opt/pulledpork-0.7.0/pulledpork.pl \
  -c ../pulledpork.conf \
  -S $SNORT_VERSION \
  -O $OINKCODE

cd $DIR

cp -r snort-release-source/. snort-pulledpork-source

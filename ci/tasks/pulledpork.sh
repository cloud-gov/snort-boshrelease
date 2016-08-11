#!/bin/bash

set -e -u -x

DIR=$(pwd)

cd snort-release-source/ci/config/snort-conf

sed -i.orig "s/<oinkcode>/$OINKCODE/" ../pulledpork.conf

perl /opt/pulledpork-0.7.0/pulledpork.pl \
  -c ../pulledpork.conf \
  -i ../disablesid.conf \
  -S $SNORT_VERSION

cd $DIR

cp -r snort-release-source/. snort-pulledpork-source

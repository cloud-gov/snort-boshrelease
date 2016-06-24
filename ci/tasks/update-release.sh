#!/bin/bash

set -e -u -x

cat << EOF > config/private.yml
$PRIVATE_YML
EOF

bosh -n sync blobs
tar czvf snort-pulledpork-source/snort-conf.tar.gz snort-release-source/ci/conf/snort

if ! cmp snort-pulledpork-source/snort-conf.tar.gz blobs/snort-conf.tar.gz ; then
  bosh -n add blob snort-pulledpork-source/snort-conf.tar.gz snort-conf.tar.gz
  bosh -n upload blobs
  bosh -n create release --force --final --with-tarball
  cp releases/snort/*.tgz finalized-release
fi

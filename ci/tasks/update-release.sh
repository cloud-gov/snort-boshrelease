#!/bin/bash

set -e -u -x

cd snort-release-source

cat << EOF > config/private.yml
$PRIVATE_YML
EOF

bosh -n sync blobs
tar czvf snort-conf.tar.gz ci/conf/snort-conf

if ! cmp snort-conf.tar.gz blobs/snort-conf.tar.gz ; then
  bosh -n add blob snort-conf.tar.gz
  bosh -n create release --force --final --with-tarball
  cp releases/snort/*.tgz ../finalized-release
fi

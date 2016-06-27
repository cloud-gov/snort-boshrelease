#!/bin/bash

set -e -u -x

cd snort-release-source

cat << EOF > config/private.yml
$PRIVATE_YML
EOF

bosh -n sync blobs
tar czvf snort-conf.tar.gz ci/config/snort-conf

if [[ $(tar -xOf snort-conf.tar.gz | sha1sum) != $(tar -xOf blobs/snort-conf.tar.gz | sha1sum) ]] ; then
  bosh -n add blob snort-conf.tar.gz
  bosh -n create release --force --final --with-tarball
  cp releases/snort/*.tgz ../finalized-release
fi

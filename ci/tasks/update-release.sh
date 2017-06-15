#!/bin/bash

set -e -u -x

cd snort-pulledpork-source

cat << EOF > config/private.yml
$PRIVATE_YML
EOF

RELEASE_NAME=`ls releases`

cp ../snort-blobs-yml/snort-blobs.yml config/blobs.yml

tar -zxf ../final-builds-dir-tarball/final-builds-dir-${RELEASE_NAME}.tgz
tar -zxf ../releases-dir-tarball/releases-dir-${RELEASE_NAME}.tgz

bosh-cli -n sync-blobs
tar czvf snort-conf.tar.gz -C ci/config snort-conf

if [ "$FORCE_UPDATE" -eq "1" ] || [ "$(tar -xOf snort-conf.tar.gz snort-conf/rules/snort.rules | sha1sum)" != "$(tar -xOf blobs/snort-conf.tar.gz snort-conf/rules/snort.rules | sha1sum)" ] ; then
  bosh-cli -n add-blob snort-conf.tar.gz snort-conf.tar.gz
  bosh-cli -n upload-blobs

  bosh-cli -n create-release --force --final --tarball=./snort.tgz
  latest_release=$(ls releases/snort/snort*.yml | grep -oe '[0-9.]\+.yml' | sed -e 's/\.yml$//' | sort -V | tail -1)
  mv snort.tgz ../finalized-release/snort-${latest_release}.tgz
else
  touch ../finalized-release/snort-0.tgz
fi

tar -czhf ../finalized-release/final-builds-dir-${RELEASE_NAME}.tgz .final_builds
tar -czhf ../finalized-release/releases-dir-${RELEASE_NAME}.tgz releases

cp -r . ../snort-bosh-source

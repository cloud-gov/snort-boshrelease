#!/bin/bash

set -e -u -x

cd snort-pulledpork-source

cat << EOF > config/private.yml
$PRIVATE_YML
EOF

RELEASE_NAME=`ls releases`

cp ../jammy-snort-blobs-yml/jammy-snort-blobs.yml config/blobs.yml

tar -zxf ../jammy-final-builds-dir-tarball/final-builds-dir-jammy-${RELEASE_NAME}.tgz
tar -zxf ../jammy-releases-dir-tarball/releases-dir-jammy-${RELEASE_NAME}.tgz

bosh-cli -n sync-blobs
tar czvf snort-conf.tar.gz -C ci/config snort-conf

if [ "$FORCE_UPDATE" -eq "1" ] || [ "$(tar -xOf snort-conf.tar.gz snort-conf/rules/snort.rules | sha1sum)" != "$(tar -xOf blobs/snort-conf.tar.gz snort-conf/rules/snort.rules | sha1sum)" ] ; then
  bosh-cli -n add-blob snort-conf.tar.gz snort-conf.tar.gz
  bosh-cli -n upload-blobs

  bosh-cli -n create-release --force --final --tarball=./jammy-snort.tgz
  latest_release=$(ls releases/jammy-snort/jammy-snort*.yml | grep -oe '[0-9.]\+.yml' | sed -e 's/\.yml$//' | sort -V | tail -1)
  mv snort.tgz ../finalized-release/jammy-snort-${latest_release}.tgz
else
  touch ../finalized-release/snort-0.tgz
fi

tar -czhf ../finalized-release/final-builds-dir-jammy-${RELEASE_NAME}.tgz .final_builds
tar -czhf ../finalized-release/releases-dir-jammy-${RELEASE_NAME}.tgz releases

cp -r . ../jammy-snort-bosh-source
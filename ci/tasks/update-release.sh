#!/bin/bash

set -e -u -x

cd snort-pulledpork-source

cat << EOF > config/private.yml
$PRIVATE_YML
EOF

cp ../snort-blobs-yml/snort-blobs.yml config/blobs.yml
bosh -n sync blobs
tar czvf snort-conf.tar.gz -C ci/config snort-conf

if [ "$(tar -xOf snort-conf.tar.gz | sha1sum)" != "$(tar -xOf blobs/snort-conf.tar.gz | sha1sum)" ] ; then
  bosh -n add blob snort-conf.tar.gz
  bosh -n upload blobs
  bosh -n create release --force --final --with-tarball

  cp releases/snort/*.tgz ../finalized-release
else
  touch ../finalized-release/snort-0.tgz
fi

cp -r . ../snort-bosh-source

#!/bin/bash

set -e -u -x

cd snort-pulledpork-source

cat << EOF > config/private.yml
$PRIVATE_YML
EOF

bosh -n sync blobs
tar czvf snort-conf.tar.gz ci/config/snort-conf

if [ "$(tar -xOf snort-conf.tar.gz | sha1sum)" != "$(tar -xOf blobs/snort-conf.tar.gz | sha1sum)" ] ; then
  bosh -n add blob snort-conf.tar.gz
  bosh -n upload blobs
  bosh -n create release --force --final --with-tarball

  git add config/blobs.yml
  git config user.name "18f"
  git config user.email "devops@gsa.gov"
  git commit -m "Update blobs."

  cp releases/snort/*.tgz ../finalized-release
else
  touch ../finalized-release/snort-dummy.tgz
fi

cp -r . ../snort-bosh-source

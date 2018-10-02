#!/bin/bash

cat << EOF > /tmp/gsc-ci-service-account.key.json
${GOOGLE_CREDENTIALS}
EOF

gcloud auth activate-service-account \
  --key-file=/tmp/gsc-ci-service-account.key.json

set -x

HADOOP_HOSTNAME="ccp-$(cat terraform_dataproc/name)-m"

echo -e "Y\n\n\n" | gcloud compute --project "data-gpdb-ud" ssh \
  --force-key-file-overwrite --zone "us-central1-a" ccp-ci-service@${HADOOP_HOSTNAME} \
  --command "hadoop distcp gs://data-gpdb-ud-tpch/${SCALE}/lineitem_data/*.tbl /tmp/lineitem_read/"

ssh -t -i ~/.ssh/google_compute_engine ccp-ci-service@${HADOOP_HOSTNAME} \
  "hadoop distcp gs://data-gpdb-ud-tpch/${SCALE}/lineitem_data/*.tbl /tmp/lineitem_read/"

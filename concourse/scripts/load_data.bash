#!/bin/bash

cat << EOF > /tmp/gsc-ci-service-account.key.json
${GOOGLE_JSON_KEY}
EOF

~/gcloud/google-cloud-sdk/bin/gcloud \
  auth activate-service-account \
  --key-file=/tmp/gsc-ci-service-account.key.json

set -x

HADOOP_HOSTNAME="ccp-$(cat terraform_dataproc/name)-m"

~/gcloud/google-cloud-sdk/bin/gcloud compute \
  --project "data-gpdb-ud" \
  ssh \
  --zone "us-central1-a" ${HADOOP_HOSTNAME} \
  --command "hadoop distcp gs://data-gpdb-ud-tpch/${SCALE}/lineitem_data/*.tbl /tmp/lineitem_read/"

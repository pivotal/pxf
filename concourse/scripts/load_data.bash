#!/usr/bin/env bash

cat << EOF > /tmp/gsc-ci-service-account.key.json
${GOOGLE_JSON_KEY}
EOF

~/gcloud/google-cloud-sdk/bin/gcloud \
    auth activate-service-account \
    --key-file=/tmp/gsc-ci-service-account.key.json

set -x

hadoop distcp gs://data-gpdb-ud-tpch/${SCALE}/lineitem_data/*.tbl /tmp/lineitem_read/


~/gcloud/google-cloud-sdk/bin/gsutil \
    -o GSUtil:parallel_composite_upload_threshold=150M \
    cp ${data}/${scale}/lineitem${i}.tbl gs://data-gpdb-ud-tpch/${scale}/lineitem_data/ &
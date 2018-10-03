#!/bin/bash

cat << EOF > /tmp/gsc-ci-service-account.key.json
${GOOGLE_CREDENTIALS}
EOF

gcloud auth activate-service-account \
  --key-file=/tmp/gsc-ci-service-account.key.json

set -x

HADOOP_HOSTNAME="ccp-$(cat terraform_dataproc/name)-m"

yum install -y -d1 openssh openssh-clients
mkdir -p ~/.ssh/
ssh-keygen -b 4096 -t rsa -f ~/.ssh/google_compute_engine -N "" -C "ccp-ci-service"

gcloud compute instances add-metadata ${HADOOP_HOSTNAME} \
  --metadata ssh-keys="$(cat ~/.ssh/google_compute_engine.pub)" \
  --zone "us-central1-a"



#echo -e "Y\n\n\n" | gcloud compute --project "data-gpdb-ud" ssh \
#  --force-key-file-overwrite --zone "us-central1-a" ccp-ci-service@${HADOOP_HOSTNAME} \
#  --command "hadoop distcp gs://data-gpdb-ud-tpch/${SCALE}/lineitem_data/*.tbl /tmp/lineitem_read/"

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
  -t -i ~/.ssh/google_compute_engine ccp-ci-service@${HADOOP_HOSTNAME} \
  "hadoop distcp gs://data-gpdb-ud-tpch/${SCALE}/lineitem_data/*.tbl /tmp/lineitem_read/" || exit 1


#gcloud dataproc jobs submit hadoop --cluster ${HADOOP_HOSTNAME} \
#  --region "us-central1" --class distcp \
#  -- gs://data-gpdb-ud-tpch/${SCALE}/lineitem_data/*.tbl /tmp/lineitem_read/

#!/bin/bash

set -e

rqf=$1
username=$2
dn=$3


now=$(date +'%s')
qa_branch="home-${rqf}-grid-${username}-${now}"
mapping="  \"${dn}\": ${username}"
commit="${rqf} home: add user ${username} to gridmap file"

if [ $# -ne 3 ]; then
    echo "Usage: cernbox-grid <RQF> <username> <DN>"
    echo "Example: cernbox-grid RQF1389645 prrout '/DC=ch/DC=cern/OU=Organic Units/OU=Users/CN=prrout/CN=790519/CN=Prasant Kumar Rout'"
    exit 1
fi

quiet_git() {
	git "$@" &> /dev/null
}

#tmp_dir=$(mktemp -d -t cernbox-grid-XXXX)
echo "Temporary directory: ${tmp_dir}"
cd $tmp_dir
quiet_git clone https://:@gitlab.cern.ch:8443/ai/it-puppet-hostgroup-eos.git
cd it-puppet-hostgroup-eos
#git checkout master
quiet_git checkout -b ${qa_branch}
echo "${mapping}" >> data/hostgroup/eos/home.yaml
quiet_git add data/hostgroup/eos/home.yaml
quiet_git commit -m "${commit}"
cherry=$(git log --oneline | head -1 | awk '{print $1}')
quiet_git push origin ${qa_branch}:qa
master_link=$(git push origin ${qa_branch} 2>&1 | grep "merge_request")

# https://gitlab.cern.ch/ai/it-puppet-hostgroup-eos/merge_requests/new?merge_request%5Bsource_branch%5D=legacy-RQF1389645-grid-prrout-1566827042
echo "Visit to create merge request: ${master_link}&merge_request%5Btarget_branch%5D=master"

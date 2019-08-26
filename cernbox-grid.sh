#!/bin/bash

rqf=$1
username=$2
dn=$3

now=$(date +'%s')
qa_branch="home-${rqf}-grid-${username}-${now}"
legacy_branch="legacy-${rqf}-grid-${username}-${now}"
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

tmp_dir=$(mktemp -d -t cernbox-grid-XXXX)
cd $tmp_dir
quiet_git clone https://:@gitlab.cern.ch:8443/ai/it-puppet-hostgroup-eos.git
cd it-puppet-hostgroup-eos
quiet_git checkout qa
echo "${mapping}" >> data/hostgroup/eos/home.yaml
quiet_git add data/hostgroup/eos/home.yaml
quiet_git commit -m "${commit}"
cherry=$(git log --oneline | head -1 | awk '{print $1}')
quiet_git push origin qa

quiet_git checkout legacy
quiet_git checkout -b ${legacy_branch} 
echo "${mapping}" >> data/hostgroup/eos/user.yaml
quiet_git add data/hostgroup/eos/user.yaml
quiet_git commit -m "${commit}"

# push branches

quiet_git checkout master
quiet_git checkout -b ${qa_branch}
quiet_git cherry-pick ${cherry}
master_link=$(git push origin ${qa_branch} 2>&1 | grep "merge_request")

quiet_git checkout ${legacy_branch}
legacy_link=$(git push origin ${legacy_branch} 2>&1 | grep "merge_request")

# https://gitlab.cern.ch/ai/it-puppet-hostgroup-eos/merge_requests/new?merge_request%5Bsource_branch%5D=legacy-RQF1389645-grid-prrout-1566827042
echo "Visit to create merge request: ${master_link}&merge_request%5Btarget_branch%5D=master"
echo "Visit to create merge request: ${legacy_link}&merge_request%5Btarget_branch%5D=legacy"

#!/bin/bash

cd `dirname "$0"`

brew install k0sproject/tap/k0sctl
if [ -d "/etc/bash_completion.d" ]; then
	k0sctl completion | sudo tee /etc/bash_completion.d/k0sctl
fi
if [ -d "/usr/local/share/zsh/site-functions/" ]; then
	k0sctl completion | sudo tee /usr/local/share/zsh/site-functions/_k0sctl
fi

k0sctl init -u debian -i ~/.ssh/id_rsa_k8s_arlsh --k0s 141.94.245.17 141.94.247.134 > k0sctl.yaml
sed -i -E 's/^(\s*role:) (controller|worker)$/\1 controller+worker/g' k0sctl.yaml
awk -i inplace -v RS= '{print gensub(/(\s*telemetry:\n\s*enabled:) true/,"\\1 false","g");}' k0sctl.yaml

k0sctl apply -c k0sctl.yaml
k0sctl kubeconfig -c k0sctl.yaml > kubeconfig.yaml
mkdir -p ~/.kube
KUBECONFIG=kubeconfig.yaml:~/.kube/config kubectl config view --flatten > .kubeconfig
mv .kubeconfig ~/.kube/config

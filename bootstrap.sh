#!/bin/bash

cd `dirname "$0"`

brew install k0sproject/tap/k0sctl
if [ -d "/etc/bash_completion.d" ]; then
	k0sctl completion | sudo tee /etc/bash_completion.d/k0sctl > /dev/null
fi
if [ -d "/usr/local/share/zsh/site-functions/" ]; then
	k0sctl completion | sudo tee /usr/local/share/zsh/site-functions/_k0sctl > /dev/null
fi

k0sctl init -u debian -i ~/.ssh/id_rsa_k8s_arlsh --k0s 141.94.247.134 141.94.245.17 > k0sctl.yaml
sed -i -E 's/^(\s*)(role:) (controller|worker|controller\+worker)$/\1\2 controller+worker\n\1installFlags:\n\1- --no-taints/g' k0sctl.yaml
awk -i inplace -v RS= '{print gensub(/(\s*telemetry:\n\s*enabled:) true/,"\\1 false","g");}' k0sctl.yaml

k0sctl apply -c k0sctl.yaml

k0sctl kubeconfig -c k0sctl.yaml --address https://141.94.247.134:6443 > kubeconfig.yaml
mkdir -p ~/.kube
KUBECONFIG=kubeconfig.yaml:~/.kube/config kubectl config view --flatten > .kubeconfig
mv .kubeconfig ~/.kube/config

if [ ! -f "id_ed25519" ]; then
	ssh-keygen -t ed25519 -N "" -f id_ed25519
fi

brew install fluxcd/tap/flux
if [ -d "/etc/bash_completion.d" ]; then
        flux completion bash | sudo tee /etc/bash_completion.d/flux > /dev/null
fi
if [ -d "/usr/local/share/zsh/site-functions/" ]; then
        flux completion zsh | sudo tee /usr/local/share/zsh/site-functions/_flux > /dev/null
fi

flux bootstrap git --url=ssh://git@github.com/arl-sh/flux-k8s.git --private-key-file=id_ed25519 --silent --path=cluster --components-extra=image-reflector-controller,image-automation-controller

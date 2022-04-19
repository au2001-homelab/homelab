#!/bin/bash

cd `dirname "$0"`

brew install k0sproject/tap/k0sctl
if [ -d "/etc/bash_completion.d" ]; then
	k0sctl completion | sudo tee /etc/bash_completion.d/k0sctl > /dev/null
fi
if [ -d "/usr/local/share/zsh/site-functions/" ]; then
	k0sctl completion | sudo tee /usr/local/share/zsh/site-functions/_k0sctl > /dev/null
fi

brew install yq

k0sctl init -u debian -i ~/.ssh/id_rsa_k8s_arlsh --k0s 141.94.247.134 141.94.245.17 > k0sctl.yaml
yq -i '.spec.hosts[].role = "controller+worker"' k0sctl.yaml
yq -i '.spec.hosts[].installFlags = ["--no-taints"]' k0sctl.yaml
yq -i '.spec.hosts[].privateInterface = "ens3"' k0sctl.yaml
yq -i '.spec.k0s.config.spec.network.kubeProxy.mode = "ipvs"' k0sctl.yaml
yq -i '.spec.k0s.config.spec.telemetry.enabled = false' k0sctl.yaml

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

flux bootstrap git --url=ssh://git@github.com/arl-sh/k8s-flux.git --private-key-file=id_ed25519 --silent --path=cluster --components-extra=image-reflector-controller,image-automation-controller

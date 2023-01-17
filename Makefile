# sudo apt install make

install-python-venv:
	sudo apt install python3.10-venv -y
	python3 -m venv .venv
	source .venv/bin/activate
	pip install --no-cache-dir -r requirement.txt

install-poetry:
	curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
	poetry --version

install-kind:
	curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
	chmod +x ./kind
	sudo mv ./kind /usr/local/bin/kind

install-kubectl:
	sudo apt-get update
	sudo apt-get install -y ca-certificates curl
	sudo apt-get install -y apt-transport-https
	sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
	echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
	sudo apt-get update
	sudo apt-get install -y kubectl
	kubectl version --client --output=yaml

install-helm:
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
	chmod 700 get_helm.sh
	./get_helm.sh
	rm get_helm.sh
	helm version

install-argo-cli:
	curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
	sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
	rm argocd-linux-amd64
	argocd

kind-cluster-create:
	kind create cluster --config kind-config.yaml
	kubectl get nodes --context kind-mlops

kind-cluster-delete:
	kind delete cluster --name mlops

k8s-cicd-install:
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update
	kubectl create namespace cicd
	helm install argocd argo/argo-cd --namespace cicd --version 5.17.1
	kubectl get services --namespace cicd

k8s-cicd-config:
	kubectl -n cicd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	f3l-SWi13ayyxm9J	


k8s-cicd-config-repository:
	argocd cluster add kind-mlops --in-cluster -y
	# add repo into argo-cd repositories
	REPOSITORY="https://github.com/Bren0Miranda/big-data-on-k8s.git"
	argocd repo add $REPOSITORY --username admin --password T9IsZr0hXY1tkA21 --port-forward

k8s-ingestion-install:
	helm repo add strimzi https://strimzi.io/charts/
	helm repo update
	kubectl create namespace ingestion
	helm install kafka strimzi/strimzi-kafka-operator --namespace ingestion --version 0.32.0
	kubectl get pod --namespace ingestion

k8s-ingestion-config-maps:
	kubectl apply -f repository/yamls/ingestion/metrics/kafka-metrics-config.yaml
	kubectl apply -f repository/yamls/ingestion/metrics/zookeeper-metrics-config.yaml
	kubectl apply -f repository/yamls/ingestion/metrics/connect-metrics-config.yaml
	kubectl apply -f repository/yamls/ingestion/metrics/cruise-control-metrics-config.yaml
	kubectl get configmaps

k8s-ingestion-config-ingestion:
	kubectl apply -f repository/app-manifests/ingestion/kafka-broker.yaml
	kubectl apply -f repository/app-manifests/ingestion/schema-registry.yaml
	kubectl apply -f repository/app-manifests/ingestion/kafka-connect.yaml
	kubectl apply -f repository/app-manifests/ingestion/cruise-control.yaml
	kubectl apply -f repository/app-manifests/ingestion/kafka-connectors.yaml


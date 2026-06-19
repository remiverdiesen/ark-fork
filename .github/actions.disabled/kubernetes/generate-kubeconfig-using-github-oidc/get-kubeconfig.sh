#!/usr/bin/env bash

# Complete script for generating kubeconfig token and setting kubeconfig for a cluster

# Requires environment variables
#   `CLUSTER_URL`,
#   `KUBECONFIG_USER_TOKEN`,
#   `IDP_ISSUER_URL`,
# to be set
if [ -z "$CLUSTER_URL" ] || [ -z "$KUBECONFIG_USER_TOKEN" ] || [ -z "$IDP_ISSUER_URL" ]; then
  echo "Requires environment variables \`CLUSTER_URL\`, \`KUBECONFIG_USER_TOKEN\`, and \`IDP_ISSUER_URL\` to be set"
  exit 1
fi

# Define variables
KUBECONFIG_PATH="${HOME}/.kube/config"

# Helper functions
errorf() {
  EC=$?
  if [ $EC -ne 0 ]
  then
    exit $EC
  fi
}

# Setup kubeconfig
echo "Setting kubeconfig"
kubeconfig_content=$(cat <<EOF
apiVersion: v1
clusters:
- cluster:
    server: ${CLUSTER_URL}/github-oidc
  name: cluster
contexts:
- context:
    cluster: cluster
    user: user
  name: context
current-context: context
kind: Config
preferences: {}
users:
- name: user
  user:
    auth-provider:
      name: oidc
      config:
        client-id: kubernetes
        client-secret: ""
        id-token: ${KUBECONFIG_USER_TOKEN[*]}
        idp-certificate-authority-data: ""
        idp-issuer-url: ${IDP_ISSUER_URL}
        refresh-token: ""
EOF
)

mkdir -p "$(dirname "${KUBECONFIG_PATH}")"
echo "${kubeconfig_content}" > "${KUBECONFIG_PATH}"
echo "Kubeconfig set successfully at path ${KUBECONFIG_PATH}:"
cat "${KUBECONFIG_PATH}"

echo "Verifying connection with cluster"
kubectl version
kubectl get namespace default -ojsonpath='{.metadata.name}' > /dev/null 2>&1 && echo "Successfully connected to cluster"
errorf

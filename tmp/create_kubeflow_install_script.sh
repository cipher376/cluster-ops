# Variables
VERSION="v1.8.0"
REPO="https://github.com/kubeflow/manifests.git"
DEST_DIR="../bootstrap/kubeflow"

mkdir -p $DEST_DIR

# Component Format: "Name:Path:SyncWave:Namespace"
components=(
  "01-cert-manager:common/cert-manager/cert-manager/base:0:cert-manager"
  "02-istio-crds:common/istio/istio-crds/base:1:istio-system"
  "03-istio-install:common/istio/istio-install/base:2:istio-system"
  "04-dex:common/dex/base:3:auth"
  "05-oidc-auth:common/oidc-authservice/base:3:istio-system"
  "06-knative-crds:common/knative/knative-serving-crds/base:4:knative-serving"
  "07-knative-install:common/knative/knative-serving-install/base:5:knative-serving"
  "08-kubeflow-namespace:common/kubeflow-namespace/base:6:kubeflow"
  "09-kubeflow-roles:common/kubeflow-roles/base:6:kubeflow"
  "10-central-dashboard:apps/centraldashboard/upstream/overlays/kserve:7:kubeflow"
  "11-admission-webhook:apps/admission-webhook/upstream/overlays/kubeflow:7:kubeflow"
  "12-notebook-controller:apps/jupyter/notebook-controller/upstream/overlays/kubeflow:8:kubeflow"
  "13-jupyter-web-app:apps/jupyter/jupyter-web-app/upstream/overlays/istio:8:kubeflow"
  "14-profiles:apps/profiles/upstream/overlays/kubeflow:8:kubeflow"
  "15-volumes-web-app:apps/volumes-web-app/upstream/overlays/istio:8:kubeflow"
  "16-tensorboard-controller:apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow:9:kubeflow"
  "17-tensorboard-web-app:apps/tensorboard/tensorboard-web-app/upstream/overlays/istio:9:kubeflow"
  "18-training-operator:apps/training-operator/upstream/overlays/kubeflow:9:kubeflow"
  "19-katib:apps/katib/upstream/overlays/kubeflow:10:kubeflow"
  "20-pipeline:apps/pipeline/upstream/overlays/kustomize:11:kubeflow"
  "21-kserve:apps/kserve/upstream/overlays/kubeflow:12:kubeflow"
)

for item in "${components[@]}"; do
  IFS=":" read -r name path wave ns <<< "$item"
  cat <<EOF > "${DEST_DIR}/${name}.yaml"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${name#*-} # Strips the number for the ArgoCD app name
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "${wave}"
spec:
  project: default
  source:
    repoURL: '${REPO}'
    targetRevision: ${VERSION}
    path: ${path}
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${ns}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
EOF
done
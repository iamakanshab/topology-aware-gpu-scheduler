module github.com/yourusername/topology-aware-gpu-scheduler

go 1.20

require (
    github.com/stretchr/testify v1.8.4
    k8s.io/api v0.28.0
    k8s.io/apimachinery v0.28.0
    k8s.io/client-go v0.28.0
    k8s.io/klog/v2 v2.100.1
    k8s.io/kubernetes v1.28.0
    k8s.io/kube-scheduler v0.28.0  // Changed from k8s.io/scheduler
)

// Replace directives for Kubernetes dependencies
replace (
    k8s.io/api => k8s.io/api v0.28.0
    k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.28.0
    k8s.io/apimachinery => k8s.io/apimachinery v0.28.0
    k8s.io/apiserver => k8s.io/apiserver v0.28.0
    k8s.io/cli-runtime => k8s.io/cli-runtime v0.28.0
    k8s.io/client-go => k8s.io/client-go v0.28.0
    k8s.io/cloud-provider => k8s.io/cloud-provider v0.28.0
    k8s.io/cluster-bootstrap => k8s.io/cluster-bootstrap v0.28.0
    k8s.io/code-generator => k8s.io/code-generator v0.28.0
    k8s.io/component-base => k8s.io/component-base v0.28.0
    k8s.io/component-helpers => k8s.io/component-helpers v0.28.0
    k8s.io/controller-manager => k8s.io/controller-manager v0.28.0
    k8s.io/cri-api => k8s.io/cri-api v0.28.0
    k8s.io/csi-translation-lib => k8s.io/csi-translation-lib v0.28.0
    k8s.io/kube-scheduler => k8s.io/kube-scheduler v0.28.0
    k8s.io/kubectl => k8s.io/kubectl v0.28.0
    k8s.io/kubelet => k8s.io/kubelet v0.28.0
    k8s.io/legacy-cloud-providers => k8s.io/legacy-cloud-providers v0.28.0
    k8s.io/metrics => k8s.io/metrics v0.28.0
    k8s.io/mount-utils => k8s.io/mount-utils v0.28.0
    k8s.io/sample-apiserver => k8s.io/sample-apiserver v0.28.0
)

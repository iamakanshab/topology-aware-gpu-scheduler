go
package v1alpha1

import (
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/apimachinery/pkg/runtime"
    "k8s.io/apimachinery/pkg/runtime/schema"
)

const (
    GroupName = "topology.scheduler.k8s.io"
    Version   = "v1alpha1"
)

var (
    // SchemeGroupVersion is the group version used to register these objects
    SchemeGroupVersion = schema.GroupVersion{
        Group:   GroupName,
        Version: Version,
    }

    // SchemeBuilder is used to add go types to the GroupVersionKind scheme
    SchemeBuilder = runtime.NewSchemeBuilder(addKnownTypes)

    // AddToScheme adds the types in this group-version to the given scheme
    AddToScheme = SchemeBuilder.AddToScheme
)

// Resource takes an unqualified resource and returns a Group qualified GroupResource
func Resource(resource string) schema.GroupResource {
    return SchemeGroupVersion.WithResource(resource).GroupResource()
}

// addKnownTypes adds our types to the API scheme by registering
func addKnownTypes(scheme *runtime.Scheme) error {
    scheme.AddKnownTypes(
        SchemeGroupVersion,
        &TopologySchedulerConfig{},
        &TopologySchedulerConfigList{},
        &DomainConfig{},
        &DomainConfigList{},
    )

    // Register the types with the Scheme so the components can map objects to GroupVersionKinds and back
    metav1.AddToGroupVersion(scheme, SchemeGroupVersion)
    return nil
}

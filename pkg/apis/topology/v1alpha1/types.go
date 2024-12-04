go
package v1alpha1

import (
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// TopologySchedulerConfig defines the configuration for topology-aware scheduling
type TopologySchedulerConfig struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`

    Spec   TopologySchedulerConfigSpec   `json:"spec"`
    Status TopologySchedulerConfigStatus `json:"status,omitempty"`
}

// TopologySchedulerConfigSpec defines the desired state of TopologySchedulerConfig
type TopologySchedulerConfigSpec struct {
    // ScoringWeights defines the weights for different scoring criteria
    ScoringWeights ScoringWeights `json:"scoringWeights"`

    // TopologyConstraints defines the constraints for topology-aware scheduling
    TopologyConstraints TopologyConstraints `json:"topologyConstraints"`

    // DomainConfigs contains configurations for different domains
    DomainConfigs []DomainConfig `json:"domainConfigs,omitempty"`

    // EnableMetrics enables or disables metric collection
    EnableMetrics bool `json:"enableMetrics,omitempty"`

    // UpdateInterval defines how often the scheduler updates its state
    UpdateInterval metav1.Duration `json:"updateInterval,omitempty"`
}

// ScoringWeights defines weights for different scoring criteria
type ScoringWeights struct {
    // ResourceAvailability weight for resource availability scoring
    ResourceAvailability float64 `json:"resourceAvailability"`

    // TopologyAlignment weight for topology alignment scoring
    TopologyAlignment float64 `json:"topologyAlignment"`

    // DomainUtilization weight for domain utilization scoring
    DomainUtilization float64 `json:"domainUtilization"`

    // HistoricalPerformance weight for historical performance scoring
    HistoricalPerformance float64 `json:"historicalPerformance"`
}

// TopologyConstraints defines constraints for topology-aware scheduling
type TopologyConstraints struct {
    // MaxNodesPerDomain maximum number of nodes per domain
    MaxNodesPerDomain int32 `json:"maxNodesPerDomain"`

    // MaxGPUsPerDomain maximum number of GPUs per domain
    MaxGPUsPerDomain int32 `json:"maxGPUsPerDomain"`

    // MinDomainsPerSpine minimum number of domains per spine
    MinDomainsPerSpine int32 `json:"minDomainsPerSpine,omitempty"`

    // MaxDomainsPerSpine maximum number of domains per spine
    MaxDomainsPerSpine int32 `json:"maxDomainsPerSpine,omitempty"`

    // AllowCrossDomainScheduling enables scheduling across domains
    AllowCrossDomainScheduling bool `json:"allowCrossDomainScheduling,omitempty"`
}

// TopologySchedulerConfigStatus defines the observed state of TopologySchedulerConfig
type TopologySchedulerConfigStatus struct {
    // ObservedGeneration represents the generation observed by the controller
    ObservedGeneration int64 `json:"observedGeneration,omitempty"`

    // LastUpdateTime timestamp of the last update
    LastUpdateTime metav1.Time `json:"lastUpdateTime,omitempty"`

    // Conditions current state of the config
    Conditions []metav1.Condition `json:"conditions,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// TopologySchedulerConfigList contains a list of TopologySchedulerConfig
type TopologySchedulerConfigList struct {
    metav1.TypeMeta `json:",inline"`
    metav1.ListMeta `json:"metadata,omitempty"`
    Items           []TopologySchedulerConfig `json:"items"`
}

// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// DomainConfig defines the configuration for a specific domain
type DomainConfig struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`

    Spec   DomainConfigSpec   `json:"spec"`
    Status DomainConfigStatus `json:"status,omitempty"`
}

// DomainConfigSpec defines the desired state of DomainConfig
type DomainConfigSpec struct {
    // Type defines the domain type (leaf/spine)
    Type string `json:"type"`

    // NetworkBandwidth available network bandwidth in Gbps
    NetworkBandwidth int32 `json:"networkBandwidth"`

    // MaxLatency maximum allowed latency in microseconds
    MaxLatency int32 `json:"maxLatency,omitempty"`

    // GPUTypes allowed GPU types in this domain
    GPUTypes []string `json:"gpuTypes,omitempty"`

    // NodeSelector selects the nodes belonging to this domain
    NodeSelector map[string]string `json:"nodeSelector,omitempty"`
}

// DomainConfigStatus defines the observed state of DomainConfig
type DomainConfigStatus struct {
    // ObservedGeneration represents the generation observed by the controller
    ObservedGeneration int64 `json:"observedGeneration,omitempty"`

    // CurrentNodes current number of nodes in the domain
    CurrentNodes int32 `json:"currentNodes"`

    // AllocatedGPUs number of allocated GPUs in the domain
    AllocatedGPUs int32 `json:"allocatedGPUs"`

    // Conditions current state of the domain
    Conditions []metav1.Condition `json:"conditions,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// DomainConfigList contains a list of DomainConfig
type DomainConfigList struct {
    metav1.TypeMeta `json:",inline"`
    metav1.ListMeta `json:"metadata,omitempty"`
    Items           []DomainConfig `json:"items"`
}

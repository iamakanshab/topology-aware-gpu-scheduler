go
package algorithm

import (
    "context"
    "fmt"
    "sort"
    "sync"
    "time"

    v1 "k8s.io/api/core/v1"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/apimachinery/pkg/labels"
    "k8s.io/apimachinery/pkg/util/sets"
    "k8s.io/kubernetes/pkg/scheduler/framework"
)

// TopologyScheduler implements the core topology-aware scheduling logic
type TopologyScheduler struct {
    sync.RWMutex
    cache            *TopologyCache
    scoreWeights     TopologyScore
    domains          map[string]*Domain
    spineConnections map[string][]string
    // For monitoring and metrics
    metrics          *MetricsCollector
    monitor          *DomainMonitor
}

// NewTopologyScheduler creates a new scheduler instance
func NewTopologyScheduler(cache *TopologyCache) *TopologyScheduler {
    ts := &TopologyScheduler{
        cache: cache,
        scoreWeights: TopologyScore{
            ResourceAvailability: 0.4,
            TopologyAlignment:    0.3,
            DomainUtilization:    0.2,
            HistoricalPerf:       0.1,
        },
        domains:          make(map[string]*Domain),
        spineConnections: make(map[string][]string),
        metrics:          NewMetricsCollector(),
    }
    ts.monitor = NewDomainMonitor(ts)
    return ts
}

// Schedule implements the main scheduling logic
func (ts *TopologyScheduler) Schedule(ctx context.Context, pod *v1.Pod) (*v1.Node, error) {
    startTime := time.Now()
    defer func() {
        ts.metrics.ObserveSchedulingLatency(time.Since(startTime))
    }()

    // Get GPU requirements
    gpuReq, err := ts.getGPURequirements(pod)
    if err != nil {
        ts.metrics.IncSchedulingError("invalid_gpu_requirements")
        return nil, fmt.Errorf("failed to get GPU requirements: %v", err)
    }

    // Determine placement strategy
    strategy := ts.getPlacementStrategy(gpuReq)
    
    // Execute placement based on strategy
    var result *PlacementResult
    switch strategy {
    case SingleDomain:
        result, err = ts.placePodSingleDomain(ctx, pod, gpuReq)
    case CompleteDomain:
        result, err = ts.placeCompleteDomain(ctx, pod, gpuReq)
    case AdjacentDomains:
        result, err = ts.placePodAdjacentDomains(ctx, pod, gpuReq)
    case MultipleDomains:
        result, err = ts.placePodMultipleDomains(ctx, pod, gpuReq)
    default:
        ts.metrics.IncSchedulingError("invalid_strategy")
        return nil, fmt.Errorf("unsupported placement strategy")
    }

    if err != nil {
        ts.metrics.IncSchedulingError(fmt.Sprintf("placement_%s", strategy))
        return nil, err
    }

    // Update metrics
    ts.metrics.ObservePlacementResult(result)
    
    // Update domain state
    ts.updateDomainState(result)

    return result.Nodes[0], nil
}

// placePodSingleDomain handles placement within a single domain
func (ts *TopologyScheduler) placePodSingleDomain(ctx context.Context, pod *v1.Pod, gpuReq *GPURequirements) (*PlacementResult, error) {
    ts.RLock()
    defer ts.RUnlock()

    // Find eligible domains
    eligibleDomains := ts.findEligibleDomains(gpuReq)
    if len(eligibleDomains) == 0 {
        return nil, fmt.Errorf("no eligible domains found for pod")
    }

    // Score domains
    scoredDomains := ts.scoreDomains(eligibleDomains, gpuReq)
    
    // Select best domain
    selectedDomain := ts.selectBestDomain(scoredDomains)
    if selectedDomain == nil {
        return nil, fmt.Errorf("failed to select domain")
    }

    // Select nodes within domain
    nodes, err := ts.selectNodesInDomain(selectedDomain, gpuReq)
    if err != nil {
        return nil, fmt.Errorf("failed to select nodes in domain: %v", err)
    }

    return &PlacementResult{
        Nodes:     nodes,
        Domain:    selectedDomain,
        Strategy:  SingleDomain,
        Score:     scoredDomains[selectedDomain],
        TimeTaken: time.Now().Sub(time.Now()), // Will be set by caller
    }, nil
}

// placeCompleteDomain handles placement requiring a complete domain
func (ts *TopologyScheduler) placeCompleteDomain(ctx context.Context, pod *v1.Pod, gpuReq *GPURequirements) (*PlacementResult, error) {
    ts.RLock()
    defer ts.RUnlock()

    // Find completely free domains
    freeDomains := ts.findCompleteFreeDomains()
    if len(freeDomains) == 0 {
        return nil, fmt.Errorf("no complete free domains available")
    }

    // Score domains
    scoredDomains := ts.scoreDomains(freeDomains, gpuReq)
    
    // Select best domain
    selectedDomain := ts.selectBestDomain(scoredDomains)
    if selectedDomain == nil {
        return nil, fmt.Errorf("failed to select domain")
    }

    return &PlacementResult{
        Nodes:     selectedDomain.Nodes,
        Domain:    selectedDomain,
        Strategy:  CompleteDomain,
        Score:     scoredDomains[selectedDomain],
        TimeTaken: time.Now().Sub(time.Now()), // Will be set by caller
    }, nil
}

// placePodAdjacentDomains handles placement across adjacent domains
func (ts *TopologyScheduler) placePodAdjacentDomains(ctx context.Context, pod *v1.Pod, gpuReq *GPURequirements) (*PlacementResult, error) {
    ts.RLock()
    defer ts.RUnlock()

    // Calculate required number of domains
    domainsNeeded := (gpuReq.NodesNeeded + 3) / 4 // Ceiling division

    // Find adjacent domain groups
    domainGroups := ts.findAdjacentDomainGroups(domainsNeeded)
    if len(domainGroups) == 0 {
        return nil, fmt.Errorf("no suitable adjacent domain groups found")
    }

    // Score domain groups
    scoredGroups := ts.scoreDomainGroups(domainGroups, gpuReq)
    
    // Select best group
    selectedGroup := ts.selectBestDomainGroup(scoredGroups)
    if selectedGroup == nil {
        return nil, fmt.Errorf("failed to select domain group")
    }

    // Select nodes across domains
    nodes, err := ts.selectNodesAcrossDomains(selectedGroup, gpuReq)
    if err != nil {
        return nil, fmt.Errorf("failed to select nodes across domains: %v", err)
    }

    return &PlacementResult{
        Nodes:     nodes,
        Domain:    selectedGroup[0], // Primary domain
        Strategy:  AdjacentDomains,
        Score:     scoredGroups[selectedGroup],
        TimeTaken: time.Now().Sub(time.Now()), // Will be set by caller
    }, nil
}

// placePodMultipleDomains handles placement across multiple domains
func (ts *TopologyScheduler) placePodMultipleDomains(ctx context.Context, pod *v1.Pod, gpuReq *GPURequirements) (*PlacementResult, error) {
    // Similar to placePodAdjacentDomains but with relaxed adjacency requirements
    return ts.placePodAdjacentDomains(ctx, pod, gpuReq)
}

// Helper functions

func (ts *TopologyScheduler) findEligibleDomains(gpuReq *GPURequirements) []*Domain {
    var eligible []*Domain
    for _, domain := range ts.domains {
        if ts.isDomainEligible(domain, gpuReq) {
            eligible = append(eligible, domain)
        }
    }
    return eligible
}

func (ts *TopologyScheduler) isDomainEligible(domain *Domain, gpuReq *GPURequirements) bool {
    availableGPUs := domain.TotalGPUs - domain.UsedGPUs
    return availableGPUs >= gpuReq.Count && len(domain.Nodes) >= gpuReq.NodesNeeded
}

func (ts *TopologyScheduler) scoreDomains(domains []*Domain, gpuReq *GPURequirements) map[*Domain]float64 {
    scores := make(map[*Domain]float64)
    for _, domain := range domains {
        scores[domain] = ts.calculateDomainScore(domain, gpuReq)
    }
    return scores
}

func (ts *TopologyScheduler) calculateDomainScore(domain *Domain, gpuReq *GPURequirements) float64 {
    // Resource availability score
    availabilityScore := float64(domain.TotalGPUs-domain.UsedGPUs) / float64(domain.TotalGPUs)
    
    // Topology alignment score
    topologyScore := ts.calculateTopologyScore(domain, gpuReq.NodesNeeded)
    
    // Domain utilization score
    utilizationScore := 1.0 - (float64(domain.UsedGPUs) / float64(domain.TotalGPUs))
    
    // Historical performance score
    perfScore := ts.getHistoricalPerformance(domain)

    // Calculate weighted score
    return (availabilityScore * ts.scoreWeights.ResourceAvailability) +
           (topologyScore * ts.scoreWeights.TopologyAlignment) +
           (utilizationScore * ts.scoreWeights.DomainUtilization) +
           (perfScore * ts.scoreWeights.HistoricalPerf)
}

func (ts *TopologyScheduler) selectBestDomain(scores map[*Domain]float64) *Domain {
    var bestDomain *Domain
    var bestScore float64

    for domain, score := range scores {
        if score > bestScore {
            bestScore = score
            bestDomain = domain
        }
    }

    return bestDomain
}

func (ts *TopologyScheduler) selectNodesInDomain(domain *Domain, gpuReq *GPURequirements) ([]*v1.Node, error) {
    var selectedNodes []*v1.Node
    
    // Get available nodes
    availableNodes := ts.getAvailableNodes(domain)
    if len(availableNodes) < gpuReq.NodesNeeded {
        return nil, fmt.Errorf("insufficient available nodes in domain")
    }

    // Sort nodes by available GPUs
    sort.Slice(availableNodes, func(i, j int) bool {
        return ts.getAvailableGPUs(availableNodes[i]) > ts.getAvailableGPUs(availableNodes[j])
    })

    // Select required nodes
    selectedNodes = availableNodes[:gpuReq.NodesNeeded]

    return selectedNodes, nil
}

// State management functions

func (ts *TopologyScheduler) updateDomainState(result *PlacementResult) {
    ts.Lock()
    defer ts.Unlock()

    for _, node := range result.Nodes {
        if domain := ts.getDomainForNode(node); domain != nil {
            domain.UsedGPUs += ts.getUsedGPUs(node)
        }
    }
}

// Recovery functions

func (ts *TopologyScheduler) HandleNodeFailure(ctx context.Context, failedNode *v1.Node) error {
    ts.Lock()
    defer ts.Unlock()

    domain := ts.getDomainForNode(failedNode)
    if domain == nil {
        return fmt.Errorf("failed node not found in any domain")
    }

    // Update domain state
    domain.UsedGPUs -= ts.getUsedGPUs(failedNode)
    
    // Remove failed node from domain
    for i, node := range domain.Nodes {
        if node.Name == failedNode.Name {
            domain.Nodes = append(domain.Nodes[:i], domain.Nodes[i+1:]...)
            break
        }
    }

    // Trigger recovery for affected workloads
    return ts.recoverWorkloads(ctx, failedNode)
}

func (ts *TopologyScheduler) recoverWorkloads(ctx context.Context, failedNode *v1.Node) error {
    // Implementation for workload recovery
    // This would involve rescheduling affected pods
    return nil
}

// Utility functions

func (ts *TopologyScheduler) getGPURequirements(pod *v1.Pod) (*GPURequirements, error) {
    var totalGPUs int64
    for _, container := range pod.Spec.Containers {
        if gpuLimit, ok := container.Resources.Limits["nvidia.com/gpu"]; ok {
            totalGPUs += gpuLimit.Value()
        }
    }

    if totalGPUs == 0 {
        return nil, fmt.Errorf("no GPU requirements specified")
    }

    return &GPURequirements{
        Count:       int(totalGPUs),
        NodesNeeded: int((totalGPUs + 3) / 4), // Ceiling division by 4 GPUs per node
    }, nil
}

func (ts *TopologyScheduler) getAvailableGPUs(node *v1.Node) int {
    // Implementation to get available GPUs on node
    return 4 // Placeholder
}

func (ts *TopologyScheduler) getUsedGPUs(node *v1.Node) int {
    // Implementation to get used GPUs on node
    return 0 // Placeholder
}

func (ts *TopologyScheduler) getDomainForNode(node *v1.Node) *Domain {
    for _, domain := range ts.domains {
        for _, n := range domain.Nodes {
            if n.Name == node.Name {
                return domain
            }
        }
    }
    return nil
}



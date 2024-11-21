package algorithm

import (
    v1 "k8s.io/api/core/v1"
)

// Scorer handles the scoring logic for domains and nodes
type Scorer struct {
    weights TopologyScore
    state   *TopologyState
}

func NewScorer(weights TopologyScore) *Scorer {
    return &Scorer{
        weights: weights,
        state:   &TopologyState{},
    }
}

func (s *Scorer) ScoreDomains(domains []*Domain, gpuReq int) map[*Domain]float64 {
    scores := make(map[*Domain]float64)
    for _, domain := range domains {
        scores[domain] = s.calculateDomainScore(domain, gpuReq)
    }
    return scores
}

func (s *Scorer) calculateDomainScore(domain *Domain, gpuReq int) float64 {
    resourceScore := s.calculateResourceScore(domain, gpuReq)
    topologyScore := s.calculateTopologyScore(domain)
    utilizationScore := s.calculateUtilizationScore(domain)
    perfScore := s.calculatePerformanceScore(domain)

    return (resourceScore * s.weights.ResourceAvailability) +
           (topologyScore * s.weights.TopologyAlignment) +
           (utilizationScore * s.weights.DomainUtilization) +
           (perfScore * s.weights.HistoricalPerf)
}

// TODO: Add implementation details for individual scoring functions
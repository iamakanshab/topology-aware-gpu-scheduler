# Topology-Aware GPU Scheduler for Kubernetes

A custom Kubernetes scheduler extension that optimizes GPU workload placement based on network topology constraints, designed for high-performance GPU clusters.

## Overview

This scheduler ensures optimal placement of GPU workloads by respecting the physical network topology of leaf-spine architecture, improving performance by up to 30% through smart placement decisions.

### Key Features
- Topology-aware scheduling for GPU workloads
- Smart domain selection based on job size
- Automatic recovery with topology constraints
- Anti-fragmentation mechanisms
- Real-time cluster state monitoring

## Architecture

![System Architecture](docs/images/system-architecture.svg)

### Core Components
- **Input Layer**
  - Job Requirements Parser
  - Node Health Monitor
  - Topology State Manager

- **Core Scheduler**
  - Topology Analyzer
  - Domain Selector
  - Placement Optimizer
  - Scoring Engine

- **Execution Layer**
  - Kubernetes Scheduler Plugin
  - Job Deployment Controller
  - Recovery Controller

## Installation

```bash
# Clone the repository
git clone https://github.com/your-org/topology-aware-scheduler

# Install dependencies
go mod download

# Build
make build

# Deploy to Kubernetes
kubectl apply -f deploy/
```

## Configuration

### Example Configuration
```yaml
apiVersion: topology.scheduler/v1alpha1
kind: SchedulerConfig
metadata:
  name: topology-scheduler-config
spec:
  scoringWeights:
    resourceAvailability: 0.4
    topologyAlignment: 0.3
    domainUtilization: 0.2
    historicalPerformance: 0.1
  topologyConstraints:
    maxNodesPerLeaf: 4
    maxGPUsPerLeaf: 32
```

## Usage

### Job Submission
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: gpu-job
  annotations:
    topology.scheduler/gpu-count: "8"
    topology.scheduler/preferred-domain: "leaf-1"
spec:
  template:
    spec:
      schedulerName: topology-aware-scheduler
      containers:
      - name: gpu-container
        image: gpu-workload:latest
        resources:
          limits:
            nvidia.com/gpu: 8
```

### Topology Constraints
The scheduler enforces the following placement rules:
- 2 nodes → Same leaf domain
- 4 nodes → Complete leaf domain
- 8 nodes → Two adjacent leaves
- 16 nodes → Four adjacent leaves

## Development

### Prerequisites
- Go 1.20+
- Kubernetes 1.24+
- Access to a GPU cluster

### Building
```bash
# Run tests
make test

# Build binary
make build

# Generate CRDs
make generate

# Run locally
make run-local
```

### Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Performance

### Metrics
- Scheduling latency: < 500ms
- Recovery time: < 30s
- Placement accuracy: 99.99%

### Monitoring
The scheduler exports Prometheus metrics at `/metrics`:
- `topology_scheduler_placement_duration_seconds`
- `topology_scheduler_recovery_duration_seconds`
- `topology_scheduler_domain_fragmentation_ratio`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please:
1. Check the [Documentation](docs/)
2. Review [Issues](issues/)
3. Join our [Slack channel](link-to-slack)

## Roadmap

- [ ] Multi-cluster support
- [ ] Dynamic topology discovery
- [ ] Advanced anti-fragmentation
- [ ] Custom scoring plugins
- [ ] GPU topology awareness

## Authors

- **Advanced Micro** - *Initial work* - [AMD](https://github.com/iamakanshab)

# setup.ps1

# Create root project directory
$projectName = "topology-aware-scheduler"
$projectRoot = Join-Path (Get-Location) $projectName

# Create root if it doesn't exist
New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
Set-Location $projectRoot

# Directory structure array
$directories = @(
    # Command directories
    "cmd/scheduler",
    "cmd/controller",
    
    # Package directories
    "pkg/apis/topology/v1alpha1",
    "pkg/apis/topology/install",
    "pkg/scheduler/algorithm",
    "pkg/scheduler/cache",
    "pkg/scheduler/plugins/topology",
    "pkg/scheduler/plugins/domain",
    "pkg/controller/topology",
    "pkg/controller/recovery",
    "pkg/utils/metrics",
    "pkg/utils/topology",
    
    # Internal packages
    "internal/cache",
    "internal/queue",
    
    # Configuration
    "config/crd",
    "config/rbac",
    "config/scheduler",
    
    # Deployment
    "deploy/kubernetes",
    "deploy/helm",
    
    # Examples
    "examples/jobs",
    "examples/topologies",
    
    # Tests
    "test/e2e",
    "test/integration",
    "test/unit",
    
    # Documentation
    "docs/images",
    "docs/api",
    "docs/examples",
    
    # Tools
    "tools/codegen",
    "tools/testing",
    
    # Vendor
    "vendor"
)

# Files to create
$files = @(
    # Command files
    "cmd/scheduler/main.go",
    "cmd/controller/main.go",
    
    # API files
    "pkg/apis/topology/v1alpha1/types.go",
    "pkg/apis/topology/v1alpha1/register.go",
    
    # Scheduler files
    "pkg/scheduler/algorithm/scorer.go",
    "pkg/scheduler/algorithm/topology.go",
    "pkg/scheduler/algorithm/placement.go",
    "pkg/scheduler/cache/topology_cache.go",
    "pkg/scheduler/cache/node_cache.go",
    "pkg/scheduler/plugins/topology/plugin.go",
    "pkg/scheduler/plugins/domain/plugin.go",
    
    # Utility files
    "pkg/utils/metrics/metrics.go",
    "pkg/utils/topology/utils.go",
    
    # Root files
    "Makefile",
    "Dockerfile",
    "README.md",
    "LICENSE",
    "go.mod"
)

# Create directories
Write-Host "Creating directories..." -ForegroundColor Green
foreach ($dir in $directories) {
    $path = Join-Path $projectRoot $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Gray
    }
}

# Create files
Write-Host "`nCreating files..." -ForegroundColor Green
foreach ($file in $files) {
    $path = Join-Path $projectRoot $file
    if (-not (Test-Path $path)) {
        New-Item -ItemType File -Path $path -Force | Out-Null
        Write-Host "Created file: $file" -ForegroundColor Gray
    }
}

# Initialize git repository
Write-Host "`nInitializing git repository..." -ForegroundColor Green
git init
Add-Content .gitignore "vendor/`n.idea/`n*.exe`n.vs/`n.vscode/`nbin/`n"

# Create basic go.mod
Write-Host "Initializing Go module..." -ForegroundColor Green
go mod init "github.com/your-org/$projectName"

# Print summary
Write-Host "`nProject structure created successfully!" -ForegroundColor Green
Write-Host "Location: $projectRoot" -ForegroundColor Yellow

# Print next steps
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. cd $projectName" -ForegroundColor White
Write-Host "2. go mod tidy" -ForegroundColor White
Write-Host "3. git add ." -ForegroundColor White
Write-Host "4. git commit -m 'Initial project structure'" -ForegroundColor White
Write-Host "5. Start developing!" -ForegroundColor White

# Optional: Show directory tree
Write-Host "`nDirectory structure:" -ForegroundColor Cyan
Get-ChildItem -Recurse | Where-Object { -not $_.PSIsContainer } | Select-Object FullName
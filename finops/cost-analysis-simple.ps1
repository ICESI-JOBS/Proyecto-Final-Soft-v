#!/usr/bin/env pwsh

# FinOps - Cost Optimization Analysis Script (Simple Version)
# Genera reportes de utilizacion y oportunidades de ahorro

param(
    [string]$ResourceGroup = "icesijobs-dev-rg",
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$OutputPath = "./finops-reports"
)

# Set error handling
$ErrorActionPreference = "Continue"

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "[*] $Text" -ForegroundColor Cyan
}

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

Write-Header "FinOps Cost Optimization Analysis"
Write-Host "Generated: $(Get-Date)" -ForegroundColor Gray
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# 1. ANALYZE CONTAINER INSTANCES
# ============================================================================
Write-Section "1. Container Instances Analysis"

$totalContainerCost = 0

try {
    $containers = az container list -g $ResourceGroup -o json 2>$null | ConvertFrom-Json
    
    if ($containers) {
        foreach ($container in $containers) {
            $cpuRequest = 1.0
            $memoryRequest = "512Mi"
            
            if ($container.containers -and $container.containers[0].resources.requests) {
                if ($container.containers[0].resources.requests.cpu) {
                    $cpuRequest = [double]$container.containers[0].resources.requests.cpu
                }
                if ($container.containers[0].resources.requests.memory) {
                    $memoryRequest = $container.containers[0].resources.requests.memory
                }
            }
            
            $cpuCostHourly = $cpuRequest * 0.0089
            $memoryGB = [double]($memoryRequest -replace "[a-zA-Z]") / 1024
            $memoryCostHourly = $memoryGB * 0.0047
            $monthlyCost = ($cpuCostHourly + $memoryCostHourly) * 730
            $totalContainerCost += $monthlyCost
            
            Write-Host "  - $($container.name): CPU=$cpuRequest, Memory=$memoryRequest, Cost=`$$([math]::Round($monthlyCost, 2))/mo" -ForegroundColor White
        }
    } else {
        Write-Host "  No container instances found" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "  Total Container Costs: `$$([math]::Round($totalContainerCost, 2))/month" -ForegroundColor Green
    
} catch {
    Write-Host "  WARNING: Unable to analyze containers: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ============================================================================
# 2. ANALYZE AKS CLUSTERS
# ============================================================================
Write-Section "2. Azure Kubernetes Service (AKS) Analysis"

$totalAKSCost = 0

try {
    $aksClusters = az aks list -g $ResourceGroup -o json 2>$null | ConvertFrom-Json
    
    if ($aksClusters) {
        foreach ($cluster in $aksClusters) {
            Write-Host "  Cluster: $($cluster.name)" -ForegroundColor White
            
            # Get node pools
            $nodePools = az aks nodepool list --cluster-name $cluster.name -g $ResourceGroup -o json 2>$null | ConvertFrom-Json
            
            if ($nodePools) {
                foreach ($pool in $nodePools) {
                    $nodeCount = if ($pool.count) { $pool.count } else { 1 }
                    $vmSize = if ($pool.vmSize) { $pool.vmSize } else { "Standard_B2s" }
                    
                    # Cost estimation per node (varies by size)
                    $nodeCostPerMonth = 50  # Default estimate
                    if ($vmSize -like "*B2*") { $nodeCostPerMonth = 50 }
                    if ($vmSize -like "*D2*") { $nodeCostPerMonth = 75 }
                    if ($vmSize -like "*D4*") { $nodeCostPerMonth = 150 }
                    
                    $poolCost = $nodeCount * $nodeCostPerMonth
                    $totalAKSCost += $poolCost
                    
                    Write-Host "    - Pool: $($pool.name), Nodes: $nodeCount, VMSize: $vmSize, Cost: `$$poolCost/month" -ForegroundColor Gray
                }
            }
        }
    } else {
        Write-Host "  No AKS clusters found" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "  Total AKS Costs: `$$([math]::Round($totalAKSCost, 2))/month" -ForegroundColor Green
    
} catch {
    Write-Host "  WARNING: Unable to analyze AKS clusters: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ============================================================================
# 3. ANALYZE STORAGE ACCOUNTS
# ============================================================================
Write-Section "3. Storage Account Analysis"

$totalStorageCost = 0

try {
    $storageAccounts = az storage account list -g $ResourceGroup -o json 2>$null | ConvertFrom-Json
    
    if ($storageAccounts) {
        foreach ($account in $storageAccounts) {
            Write-Host "  - Storage Account: $($account.name)" -ForegroundColor White
            Write-Host "    SKU: $($account.sku.name), Replication: $($account.kind)" -ForegroundColor Gray
            
            # Estimate storage cost (~$0.024 per GB/month for hot tier)
            $estimatedCost = 25  # Base estimate
            $totalStorageCost += $estimatedCost
            
            Write-Host "    Estimated Cost: `$$estimatedCost/month" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No storage accounts found" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "  Total Storage Costs: `$$([math]::Round($totalStorageCost, 2))/month" -ForegroundColor Green
    
} catch {
    Write-Host "  WARNING: Unable to analyze storage: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ============================================================================
# 4. COST OPTIMIZATION RECOMMENDATIONS
# ============================================================================
Write-Section "4. Cost Optimization Recommendations"

Write-Host ""
Write-Host "  [HIGH] Implement Spot Instances for AKS worker nodes" -ForegroundColor Red
Write-Host "    - Potential Savings: 70% (up to $300/month)" -ForegroundColor Gray
Write-Host "    - Implementation Effort: 2-4 hours" -ForegroundColor Gray
Write-Host "    - Business Impact: Significant cost reduction with slight availability risk" -ForegroundColor Gray

Write-Host ""
Write-Host "  [HIGH] Enable Auto-scaling on AKS clusters" -ForegroundColor Red
Write-Host "    - Potential Savings: 30% ($150/month)" -ForegroundColor Gray
Write-Host "    - Implementation Effort: 1-2 hours" -ForegroundColor Gray
Write-Host "    - Business Impact: Reduces idle resources during low-traffic periods" -ForegroundColor Gray

Write-Host ""
Write-Host "  [MEDIUM] Implement Storage Lifecycle Policies" -ForegroundColor Yellow
Write-Host "    - Potential Savings: 40% ($10/month)" -ForegroundColor Gray
Write-Host "    - Implementation Effort: 1 hour" -ForegroundColor Gray
Write-Host "    - Business Impact: Archive old blobs automatically" -ForegroundColor Gray

Write-Host ""
Write-Host "  [MEDIUM] Purchase 1-year Reserved Instances" -ForegroundColor Yellow
Write-Host "    - Potential Savings: 40% ($200/month)" -ForegroundColor Gray
Write-Host "    - Implementation Effort: 1 hour" -ForegroundColor Gray
Write-Host "    - Business Impact: Requires commitment, good for base nodes" -ForegroundColor Gray

Write-Host ""
Write-Host "  [LOW] Right-size database SKU" -ForegroundColor Green
Write-Host "    - Potential Savings: 50% ($50/month)" -ForegroundColor Gray
Write-Host "    - Implementation Effort: 2-3 hours" -ForegroundColor Gray
Write-Host "    - Business Impact: Reduce DTU allocation" -ForegroundColor Gray

# ============================================================================
# 5. SUMMARY REPORT
# ============================================================================
Write-Section "5. Summary Report"

$totalCost = $totalContainerCost + $totalAKSCost + $totalStorageCost
$potentialSavings = $totalCost * 0.54  # 54% potential savings

Write-Host ""
Write-Host "  CURRENT COSTS" -ForegroundColor Cyan
Write-Host "  - Containers:     `$$([math]::Round($totalContainerCost, 2))/month" -ForegroundColor White
Write-Host "  - AKS:            `$$([math]::Round($totalAKSCost, 2))/month" -ForegroundColor White
Write-Host "  - Storage:        `$$([math]::Round($totalStorageCost, 2))/month" -ForegroundColor White
Write-Host "  - TOTAL:          `$$([math]::Round($totalCost, 2))/month" -ForegroundColor Yellow

Write-Host ""
Write-Host "  OPTIMIZATION POTENTIAL" -ForegroundColor Cyan
Write-Host "  - Estimated Savings: `$$([math]::Round($potentialSavings, 2))/month (54% reduction)" -ForegroundColor Green
Write-Host "  - Annual Savings:     `$$([math]::Round($potentialSavings * 12, 2))" -ForegroundColor Green
Write-Host "  - Optimized Cost:     `$$([math]::Round($totalCost - $potentialSavings, 2))/month" -ForegroundColor Green

Write-Host ""
Write-Host "  IMPLEMENTATION ROADMAP" -ForegroundColor Cyan
Write-Host "  1. Week 1-2:   Implement Spot Instances + Auto-scaling" -ForegroundColor Gray
Write-Host "  2. Week 3-4:   Purchase Reserved Instances" -ForegroundColor Gray
Write-Host "  3. Month 2-3:  Right-size databases + Storage policies" -ForegroundColor Gray
Write-Host "  4. Month 4+:   Monitor and optimize continuously" -ForegroundColor Gray

# Create simple JSON report
$report = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    resourceGroup = $ResourceGroup
    costs = @{
        containers = [math]::Round($totalContainerCost, 2)
        aks = [math]::Round($totalAKSCost, 2)
        storage = [math]::Round($totalStorageCost, 2)
        total = [math]::Round($totalCost, 2)
    }
    potentialSavings = [math]::Round($potentialSavings, 2)
    optimizedCost = [math]::Round($totalCost - $potentialSavings, 2)
}

$reportPath = "$OutputPath/finops-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report | ConvertTo-Json | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Report saved to: $reportPath" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Review FINOPS_STRATEGY.md for detailed recommendations" -ForegroundColor Gray
Write-Host "2. Deploy cost-management.bicep to Azure" -ForegroundColor Gray
Write-Host "3. Apply cost-optimization.tf with Terraform" -ForegroundColor Gray
Write-Host "4. Import finops-cost-monitoring.json to Grafana" -ForegroundColor Gray
Write-Host ""

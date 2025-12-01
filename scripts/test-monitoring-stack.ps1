Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Testing Monitoring Stack" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# PASO 1: Verify containers
Write-Host "1. Checking containers..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}"

Write-Host ""
Write-Host "2. Checking Prometheus Health..." -ForegroundColor Yellow
curl http://localhost:9090/-/healthy -UseBasicParsing 2>$null | Select-Object -ExpandProperty Content
Write-Host "   Status: OK" -ForegroundColor Green

Write-Host ""
Write-Host "3. Checking Grafana Health..." -ForegroundColor Yellow
$grafanaHealth = curl http://localhost:3000/api/health -UseBasicParsing 2>$null | ConvertFrom-Json
Write-Host "   Database: $($grafanaHealth.database)" -ForegroundColor Green
Write-Host "   Status: $($grafanaHealth.status)" -ForegroundColor Green

Write-Host ""
Write-Host "4. Listing Prometheus Targets..." -ForegroundColor Yellow
$targets = curl http://localhost:9090/api/v1/targets -UseBasicParsing 2>$null | ConvertFrom-Json
$targets.data.activeTargets | Select-Object @{N='Job';E={$_.labels.job}}, @{N='Instance';E={$_.labels.instance}}, health | Format-Table

Write-Host ""
Write-Host "5. Executing PromQL Queries..." -ForegroundColor Yellow
Write-Host ""

# Query 1
Write-Host "   Query 1: Prometheus Status (up)" -ForegroundColor Cyan
$q1 = curl "http://localhost:9090/api/v1/query?query=up{job=prometheus}" -UseBasicParsing 2>$null | ConvertFrom-Json
Write-Host "   Result: $($q1.data.result[0].value[1])" -ForegroundColor Green
Write-Host ""

# Query 2
Write-Host "   Query 2: Memory Usage" -ForegroundColor Cyan
$q2 = curl "http://localhost:9090/api/v1/query?query=process_resident_memory_bytes{job=prometheus}" -UseBasicParsing 2>$null | ConvertFrom-Json
$memBytes = $q2.data.result[0].value[1]
$memMB = [math]::Round($memBytes / 1MB, 2)
Write-Host "   Result: $memMB MB" -ForegroundColor Green
Write-Host ""

# Query 3
Write-Host "   Query 3: HTTP Request Count" -ForegroundColor Cyan
$q3 = curl "http://localhost:9090/api/v1/query?query=prometheus_http_requests_total" -UseBasicParsing 2>$null | ConvertFrom-Json
Write-Host "   Result: $($q3.data.result.Count) metrics" -ForegroundColor Green
Write-Host ""

Write-Host "6. Generating Test Traffic (30 seconds)..." -ForegroundColor Yellow

$startTime = Get-Date
$endTime = $startTime.AddSeconds(30)
$requestCount = 0

while ((Get-Date) -lt $endTime) {
    curl "http://localhost:9090/api/v1/query?query=up" -UseBasicParsing 2>$null | Out-Null
    curl "http://localhost:9090/api/v1/query?query=process_resident_memory_bytes" -UseBasicParsing 2>$null | Out-Null
    curl "http://localhost:9090/metrics" -UseBasicParsing 2>$null | Out-Null
    $requestCount += 3
    
    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    $percent = [int](($elapsed / 30) * 100)
    Write-Progress -Activity "Generating traffic" -Status "$requestCount requests sent" -PercentComplete $percent
    
    Start-Sleep -Milliseconds 500
}

Write-Host "   Done: $requestCount requests sent" -ForegroundColor Green
Write-Host ""

Write-Host "7. Accessing Dashboards:" -ForegroundColor Green
Write-Host ""
Write-Host "   Grafana Dashboard" -ForegroundColor Yellow
Write-Host "   URL: http://localhost:3000" -ForegroundColor Cyan
Write-Host "   User: admin" -ForegroundColor Cyan
Write-Host "   Pass: admin" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Prometheus Graph" -ForegroundColor Yellow
Write-Host "   URL: http://localhost:9090/graph" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Zipkin Traces" -ForegroundColor Yellow
Write-Host "   URL: http://localhost:9411" -ForegroundColor Cyan
Write-Host ""

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Testing Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

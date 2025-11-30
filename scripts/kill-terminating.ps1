Write-Host "Buscando pods en estado Terminating..."

$pods = kubectl get pods -n icesi-dev | Select-String "Terminating"

foreach ($p in $pods) {
    $name = ($p -split "\s+")[0]
    Write-Host "Eliminando pod: $name"
    kubectl delete pod $name -n icesi-dev --force --grace-period=0
}

Write-Host "`n---"
Write-Host "Proceso completado."

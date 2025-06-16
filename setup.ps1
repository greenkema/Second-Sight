if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not in PATH"
    exit 1
}

if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Error "Docker Compose is not installed or not in PATH"
    exit 1
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.sample" ".env"
    Write-Host "Created .env file from .env.sample"
}

$directories = @("data/consul", "data/prometheus", "data/grafana", "data/alertmanager", "data/pyroscope", "logs")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "Created directory: $dir"
    }
}

Write-Host "Starting services..."
docker-compose up -d

Write-Host "Waiting for services to start..."
Start-Sleep -Seconds 30

Write-Host "Services are starting up. You can access:"
Write-Host "- Consul UI: http://localhost:8500"
Write-Host "- Prometheus: http://localhost:9090"
Write-Host "- Grafana: http://localhost:3000 (admin/admin)"
Write-Host "- Alertmanager: http://localhost:9093"
Write-Host "- Pyroscope: http://localhost:4040"
Write-Host "- Node Exporter: http://localhost:9100"
Write-Host "- Consul Exporter: http://localhost:9107"
Write-Host ""
Write-Host "To stop all services: docker-compose down"
Write-Host "To view logs: docker-compose logs -f [service-name]"
# PowerShell脚本 - 设置监控系统配置

# 创建配置目录结构
Write-Host "创建配置目录结构..." -ForegroundColor Green

$directories = @(
    "config\consul\server1",
    "config\consul\server2",
    "config\consul\server3",
    "config\prometheus\rules",
    "config\grafana\provisioning\datasources",
    "config\grafana\provisioning\dashboards",
    "config\grafana\provisioning\notifiers",
    "config\grafana\provisioning\plugins",
    "config\grafana\dashboards",
    "config\alertmanager\template",
    "config\pyroscope"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "  创建目录: $dir" -ForegroundColor Gray
    }
}

# 检查.env文件是否存在
if (-not (Test-Path ".env")) {
    Write-Host "错误: .env文件不存在，请确保.env文件已创建" -ForegroundColor Red
    exit 1
}

# 检查Consul加密密钥
$envContent = Get-Content ".env" -Raw
if ($envContent -match "your_generated_encryption_key_here") {
    Write-Host "需要生成Consul加密密钥..." -ForegroundColor Yellow
    Write-Host "请运行以下命令生成密钥:" -ForegroundColor Yellow
    Write-Host "  docker run --rm consul consul keygen" -ForegroundColor Cyan
    Write-Host "然后将生成的密钥更新到.env文件中的CONSUL_ENCRYPT_KEY变量" -ForegroundColor Yellow
}

# 检查Grafana密码
if ($envContent -match "secure_password_here") {
    Write-Host "警告: 请更改.env文件中的默认Grafana密码" -ForegroundColor Yellow
}

# 创建配置文件目录结构的说明
Write-Host "
配置目录结构已创建。请确保以下配置文件存在:" -ForegroundColor Green
Write-Host "  - config\prometheus\prometheus.yml" -ForegroundColor Gray
Write-Host "  - config\alertmanager\alertmanager.yml" -ForegroundColor Gray
Write-Host "  - config\pyroscope\pyroscope.yml" -ForegroundColor Gray
Write-Host "  - config\consul\server1\config.json" -ForegroundColor Gray
Write-Host "  - config\grafana\provisioning\datasources\prometheus.yml" -ForegroundColor Gray

Write-Host "
设置完成，现在可以运行 'docker-compose up -d' 启动服务" -ForegroundColor Green
#!/bin/bash

echo "Setting up Consul monitoring stack..."

if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

if [ ! -f ".env" ]; then
    echo "Creating .env file from .env.sample..."
    cp .env.sample .env
    echo "Please edit .env file with your specific configuration."
fi

# 生成Consul加密密钥（如果需要）
if grep -q "your_generated_encryption_key_here" .env; then
  echo "生成Consul加密密钥..."
  CONSUL_KEY=$(docker run --rm consul:1.15.4 consul keygen)
  sed -i "s/your_generated_encryption_key_here/$CONSUL_KEY/" .env
  echo "Consul加密密钥已更新到.env文件"
fi

echo "Creating necessary directories..."
mkdir -p data/consul/server1
mkdir -p data/consul/server2
mkdir -p data/consul/server3
mkdir -p data/prometheus
mkdir -p data/grafana
mkdir -p data/alertmanager
mkdir -p data/pyroscope
mkdir -p logs

echo "Setting permissions..."
chmod -R 755 data
chmod -R 755 logs

echo "Starting services..."
docker compose up -d

echo "Waiting for services to start..."
sleep 30

echo "Setup complete!"
echo "Services available at:"
echo "  - Consul UI: http://localhost:8500"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3000 (admin/admin)"
echo "  - Alertmanager: http://localhost:9093"
echo "  - Pyroscope: http://localhost:4040"
echo "  - Node Exporter: http://localhost:9100"
echo "  - Consul Exporter: http://localhost:9107"

echo "To stop all services: docker compose down"
echo "To view logs: docker compose logs -f [service_name]"
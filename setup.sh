#!/bin/bash

# 创建配置目录结构
mkdir -p config/consul/server{1,2,3}
mkdir -p config/prometheus/rules
mkdir -p config/grafana/{provisioning/{datasources,dashboards,notifiers,plugins},dashboards}
mkdir -p config/alertmanager/template
mkdir -p config/pyroscope

# 复制配置文件（如果不存在）
if [ ! -f config/prometheus/prometheus.yml ]; then
  cp -n config-templates/prometheus/prometheus.yml config/prometheus/
fi

if [ ! -f config/alertmanager/alertmanager.yml ]; then
  cp -n config-templates/alertmanager/alertmanager.yml config/alertmanager/
fi

if [ ! -f config/pyroscope/pyroscope.yml ]; then
  cp -n config-templates/pyroscope/pyroscope.yml config/pyroscope/
fi

if [ ! -f config/consul/server1/config.json ]; then
  cp -n config-templates/consul/server1/config.json config/consul/server1/
fi

if [ ! -f config/grafana/provisioning/datasources/prometheus.yml ]; then
  cp -n config-templates/grafana/provisioning/datasources/prometheus.yml config/grafana/provisioning/datasources/
fi

# 检查.env文件是否存在
if [ ! -f .env ]; then
  echo "错误: .env文件不存在，请从.env.example创建"
  exit 1
fi

# 生成Consul加密密钥（如果需要）
if grep -q "your_generated_encryption_key_here" .env; then
  echo "生成Consul加密密钥..."
  CONSUL_KEY=$(docker run --rm consul consul keygen)
  sed -i "s/your_generated_encryption_key_here/$CONSUL_KEY/" .env
  echo "Consul加密密钥已更新到.env文件"
fi

# 设置文件权限
chmod -R 755 config

echo "设置完成，现在可以运行 'docker-compose up -d' 启动服务"
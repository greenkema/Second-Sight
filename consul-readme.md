# Consul集群部署指南

本文档提供了使用Docker Compose部署3节点Consul集群的详细说明。此配置适用于生产环境，采用server模式，并针对内网环境进行了安全配置。

## 前置条件

- Docker (20.10.0+)
- Docker Compose (2.0.0+)
- Linux或支持Docker的操作系统

## 文件结构

```
./
├── docker-compose.yaml  # Consul集群配置文件
├── .env                 # 环境变量配置文件
└── consul-readme.md     # 本说明文档
```

## 快速开始

### 1. 生成加密密钥

在启动集群前，需要生成用于Consul节点间通信加密的密钥：

```bash
docker run --rm consul consul keygen
```

### 2. 配置环境变量

将上一步生成的密钥添加到`.env`文件中：

```
CONSUL_ENCRYPT_KEY=生成的密钥值
```

### 3. 启动集群

```bash
docker compose up -d
```

### 4. 验证集群状态

```bash
docker exec consul-server1 consul members
```

正常情况下，应该看到所有三个节点都处于alive状态。

## 集群配置说明

### 节点配置

- **consul-server1**: 引导节点，提供UI界面，对外暴露API和DNS接口
- **consul-server2**: 服务器节点，仅内部网络可访问
- **consul-server3**: 服务器节点，仅内部网络可访问

### 网络配置

- 创建名为`consul-net`的桥接网络
- 子网配置为`172.28.0.0/16`
- 仅`consul-server1`暴露必要端口到主机

### 端口说明

- **8500**: HTTP API接口和Web UI
- **8600**: DNS接口(TCP和UDP)

## 安全建议

对于生产环境，建议进一步加强安全措施：

1. **配置TLS证书**：为API和集群通信启用TLS加密

   ```yaml
   # 在docker-compose.yaml的command部分添加
   -ca-file=/consul/config/ca.pem \
   -cert-file=/consul/config/server.pem \
   -key-file=/consul/config/server-key.pem
   ```

2. **启用ACL系统**：限制对Consul API的访问

   ```yaml
   # 在docker-compose.yaml的command部分添加
   -acl-enable=true \
   -acl-default-policy=deny \
   -acl-master-token=your-master-token
   ```

3. **限制网络访问**：使用防火墙规则限制对Consul服务的访问

4. **定期备份**：设置定期备份Consul数据的策略

## 维护操作

### 查看日志

```bash
docker compose logs -f
```

### 扩展集群

修改`docker-compose.yaml`添加新节点，确保新节点的`retry-join`配置包含现有节点。

### 重启集群

```bash
docker compose restart
```

### 完全重建集群

```bash
docker compose down -v
docker compose up -d
```

## 故障排除

1. **节点无法加入集群**：检查加密密钥是否一致，网络是否通畅
2. **UI无法访问**：确认8500端口是否正确映射和防火墙设置
3. **DNS查询失败**：验证8600端口配置和DNS服务是否正常运行

## 监控系统集成

本项目集成了完整的监控系统解决方案，包含以下组件：

### Prometheus

- **功能**：时序数据库和监控系统，负责收集和存储指标数据
- **配置文件**：`config/prometheus/prometheus.yml`
- **告警规则**：`config/prometheus/rules/consul_alerts.yml`
- **端口**：9090（Web UI和API）
- **特点**：
  - 自动从Consul发现服务并监控
  - 支持高基数指标和长期存储
  - 强大的查询语言PromQL
  - 数据保留期15天

### Grafana

- **功能**：数据可视化和仪表板平台
- **配置文件**：`config/grafana/provisioning/`
- **数据源**：自动配置Prometheus、Alertmanager和Pyroscope
- **端口**：3000（Web UI）
- **特点**：
  - 预装常用面板插件
  - 支持多种数据源
  - 可通过`provisioning`目录添加自定义仪表板
  - 强大的告警和通知功能

### Alertmanager

- **功能**：告警管理和通知系统
- **配置文件**：`config/alertmanager/alertmanager.yml`
- **端口**：9093（Web UI和API）
- **特点**：
  - 支持邮件、Slack、PagerDuty等多种通知方式
  - 告警分组和路由功能
  - 告警静默和抑制
  - 与Grafana集成，支持可视化管理告警

### Pyroscope

- **功能**：连续性能分析工具，用于监控和可视化应用程序性能
- **配置文件**：`config/pyroscope/pyroscope.yml`
- **端口**：4040（Web UI和API）
- **特点**：
  - 支持从Consul发现服务
  - 低开销的性能分析
  - 支持多种编程语言
  - 与Grafana集成，提供统一的可视化界面
  - 数据保留期30天

### 监控系统使用指南

1. **访问Grafana**：浏览器打开 http://localhost:3000 (默认用户名/密码: admin/admin)
2. **查看Prometheus**：浏览器打开 http://localhost:9090
3. **管理告警**：浏览器打开 http://localhost:9093
4. **性能分析**：浏览器打开 http://localhost:4040

### 添加监控目标

1. 在Prometheus配置中添加新的抓取配置
2. 重启Prometheus服务

```bash
docker compose restart prometheus
```

### 添加自定义告警规则

1. 在`config/prometheus/rules/`目录下创建新的规则文件
2. 重启Prometheus服务

---

**注意**：本配置仅提供基础的生产环境部署，根据实际需求可能需要进一步调整和优化。
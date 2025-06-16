# 分布式监控系统

本项目是一个完整的分布式监控系统，集成了多种开源监控工具，用于监控和可视化应用程序和基础设施的性能指标、日志和跟踪数据。

## 系统组件

- **Consul**: 服务发现和配置管理
  - 访问地址: http://localhost:8500
- **Prometheus**: 时间序列数据库和监控系统
  - 访问地址: http://localhost:9090
- **Grafana**: 数据可视化和仪表板
  - 访问地址: http://localhost:3000
- **Alertmanager**: 告警处理和通知
  - 访问地址: http://localhost:9093
- **Pyroscope**: 连续性能分析
  - 访问地址: http://localhost:4040
- **Node Exporter**: 主机指标收集
  - 访问地址: http://localhost:9100/metrics
- **Consul Exporter**: Consul指标收集
- **Grafana Alloy**: 遥测数据收集和处理
  - 访问地址: http://localhost:12345
  - OTLP gRPC端点: localhost:4317
  - OTLP HTTP端点: http://localhost:4318
- **阿里云SLS**: 日志服务，用于日志聚合和查询
  - 通过Grafana配置数据源访问

## 快速开始

### 前提条件

- Docker和Docker Compose已安装
- 阿里云账号并开通SLS服务

### 配置步骤

1. 克隆仓库

```bash
git clone https://github.com/yourusername/distributed-monitoring.git
cd distributed-monitoring
```

2. 生成Consul加密密钥

```bash
docker run --rm consul consul keygen
```

3. 创建.env文件并添加必要的环境变量

```bash
CONSUL_ENCRYPT_KEY=<生成的密钥>
GRAFANA_ADMIN_PASSWORD=admin  # 可以修改为更安全的密码
SLS_PROJECT=<阿里云SLS项目名称>
SLS_ENDPOINT=<阿里云SLS端点，例如：cn-hangzhou.log.aliyuncs.com>
SLS_LOGSTORE=<阿里云SLS日志库名称>
SLS_ACCESS_KEY_ID=<阿里云访问密钥ID>
SLS_ACCESS_KEY_SECRET=<阿里云访问密钥密码>
```

4. 创建必要的配置文件目录

```bash
mkdir -p config/{consul/{server1,server2,server3},prometheus,grafana/{provisioning,dashboards},alertmanager,pyroscope,alloy}
```

5. 启动系统

```bash
docker-compose up -d
```

6. 访问Grafana

打开浏览器访问 http://localhost:3000，使用默认用户名 `admin` 和在.env文件中设置的密码登录。

## 目录结构

```
.
├── config/                     # 配置文件目录
│   ├── alertmanager/          # Alertmanager配置
│   ├── alloy/                 # Grafana Alloy配置
│   ├── consul/                # Consul配置
│   │   ├── server1/           # Consul server1配置
│   │   ├── server2/           # Consul server2配置
│   │   └── server3/           # Consul server3配置
│   ├── grafana/               # Grafana配置
│   │   ├── dashboards/        # Grafana仪表板
│   │   └── provisioning/      # Grafana自动配置
│   ├── prometheus/            # Prometheus配置
│   └── pyroscope/             # Pyroscope配置
├── docker-compose.yaml        # Docker Compose配置文件
├── .env                       # 环境变量文件
└── README.md                  # 项目说明文档
```

## 配置说明

### Consul

Consul集群由三个服务器节点组成，用于服务发现和配置管理。配置文件位于 `config/consul/` 目录下。

### Prometheus

Prometheus用于收集和存储指标数据。配置文件位于 `config/prometheus/prometheus.yml`。

### Grafana

Grafana用于数据可视化和仪表板。配置文件位于 `config/grafana/` 目录下。

### Alertmanager

Alertmanager用于处理告警和通知。配置文件位于 `config/alertmanager/alertmanager.yml`。

### Pyroscope

Pyroscope用于连续性能分析。配置文件位于 `config/pyroscope/pyroscope.yml`。

### Grafana Alloy

Grafana Alloy是一个强大的遥测数据收集和处理工具，可以收集日志、指标和跟踪数据。配置文件位于 `config/alloy/config.alloy`。

#### 日志收集

Alloy配置为从文件中收集日志，并将其发送到阿里云SLS：

```river
local.file_match "logs" {
  path_targets = [
    {path = "/var/log/app/*.log", pipeline = "logs"},
  ]
}

loki.source.file "logs" {
  targets    = local.file_match.logs.targets
  forward_to = [loki.process.logs.receiver]
}

loki.process "logs" {
  forward_to = [http.client.sls.sender]
}
```

#### 指标转发

Alloy配置为将指标转发到Prometheus：

```river
prometheus.remote_write "default" {
  endpoint {
    url = "http://prometheus:9090/api/v1/write"
  }
}
```

#### OTLP接收器

Alloy配置为接收OpenTelemetry数据：

```river
otel.receiver.otlp "default" {
  grpc {
    endpoint = "0.0.0.0:4317"
  }
  http {
    endpoint = "0.0.0.0:4318"
  }
  output {
    metrics = [prometheus.remote_write.default.receiver]
    logs    = [http.client.sls.sender]
    traces  = [otel.exporter.otlp.traces.sender]
  }
}
```

### 阿里云SLS

阿里云SLS（日志服务）是一个完全托管的实时日志数据收集、消费、存储和分析服务。在本系统中，Grafana Alloy被配置为将日志数据发送到阿里云SLS。

#### 配置阿里云SLS

1. 在阿里云控制台创建SLS项目和日志库
2. 获取必要的访问凭证（AccessKey ID和Secret）
3. 在.env文件中配置SLS相关环境变量
4. 在Grafana中添加阿里云SLS数据源

## 数据保留期

- **Prometheus**: 15天（可在docker-compose.yaml中修改）
- **Pyroscope**: 默认为7天（可在pyroscope.yml中修改）
- **阿里云SLS**: 根据阿里云SLS配置（默认为30天，可在阿里云控制台修改）

## 故障排除

### 服务无法启动

检查Docker日志以获取详细错误信息：

```bash
docker-compose logs <服务名>
```

### 无法收集数据

1. 检查网络连接
2. 检查配置文件是否正确
3. 检查目标服务是否正常运行

### UI无法访问

1. 检查服务是否正常运行
2. 检查端口映射是否正确
3. 检查防火墙设置

### 配置重载失败

1. 检查配置文件语法是否正确
2. 尝试重启服务

```bash
docker-compose restart <服务名>
```

## 维护操作

### 查看日志

```bash
docker-compose logs -f <服务名>
```

### 重新加载配置

对于支持热重载的服务（如Prometheus）：

```bash
curl -X POST http://localhost:9090/-/reload
```

### 重启服务

```bash
docker-compose restart <服务名>
```

### 停止服务

```bash
docker-compose stop <服务名>
```

### 完全移除

```bash
docker-compose down -v
```

## 扩展指南

### 添加更多Exporters

可以添加更多的Prometheus Exporters来监控其他服务，例如MySQL Exporter、Redis Exporter等。

### 自定义仪表板

可以在Grafana中创建自定义仪表板，或者导入社区提供的仪表板。

### 配置告警规则

可以在Prometheus中配置告警规则，并通过Alertmanager发送通知。

## 参考资源

- [Consul文档](https://www.consul.io/docs)
- [Prometheus文档](https://prometheus.io/docs/introduction/overview/)
- [Grafana文档](https://grafana.com/docs/grafana/latest/)
- [Alertmanager文档](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Pyroscope文档](https://pyroscope.io/docs/)
- [Grafana Alloy文档](https://grafana.com/docs/alloy/latest/)
- [阿里云SLS文档](https://help.aliyun.com/product/28958.html)

## 许可证

本项目采用MIT许可证。详见LICENSE文件。
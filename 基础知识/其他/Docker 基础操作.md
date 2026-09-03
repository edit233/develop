---
title: Docker 基础操作
tags: [Docker, 大类, 容器, 镜像, 部署, Compose]
created: 2026-08-09
---

## 概述
Docker 部署标准写法：核心概念、docker run 参数、常用命令、开机自启、数据卷挂载、Dockerfile 自定义镜像、网络互联、Docker Compose 多容器编排。全部为可复用标准代码，参数处中文注明。

## 核心概念
- **镜像（Image）**：包含应用本身及其运行所需环境、配置、系统函数库的文件集合，按操作步骤分层叠加（每层为 Layer），可复用已有基础镜像
- **容器（Container）**：镜像运行后形成的隔离环境实例
- **Registry（镜像仓库）**：存储镜像的网站（如 DockerHub），镜像名格式 `仓库名:标签`，不指定标签默认 `latest`
- 用 Docker 部署软件 = 自动搜索下载镜像 → 创建并运行容器，跨系统无需手动配置环境

## 部署 MySQL（docker run 参数解读）
标准完整代码：
```powershell
docker run -d \
  --name mysql \
  -p 3307:3306 \
  -e TZ=Asia/Shanghai \
  -e MYSQL_ROOT_PASSWORD=123 \
  mysql:8.0
```
参数说明：
- `-d`：后台运行容器
- `--name mysql`：容器名（可自定义）
- `-p 宿主机端口:容器内端口`：端口映射。容器是隔离环境，外界不可直接访问，需将宿主机端口映射到容器内端口；容器内端口由进程决定（如 MySQL 默认 3306），宿主机端口可任意指定
- `-e KEY=VALUE`：设置容器内进程的运行参数（如时区、MySQL 默认密码），KEY/VALUE 由镜像决定
- `mysql:8.0`：镜像名 `REPOSITORY:TAG`，Docker 按此名称自动搜索下载并运行镜像

## 常用命令
| 命令 | 说明 |
|---|---|
| docker pull / push | 拉取镜像 / 推送镜像到 Registry |
| docker images / rmi | 查看本地镜像 / 删除本地镜像 |
| docker run | 创建并运行容器（同名容器不能重复创建） |
| docker ps / ps -a | 查看运行中容器 / 查看所有容器 |
| docker stop / start / restart | 停止 / 启动 / 重启容器 |
| docker rm / rm -f | 删除容器（运行中需 -f 强制删除） |
| docker logs | 查看容器日志 |
| docker exec -it 容器名 sh | 进入容器内执行命令 |
| docker inspect | 查看容器详细信息（网络 IP、挂载、配置等） |
| docker save / load | 镜像保存为本地压缩文件 / 从压缩文件加载镜像 |

补充：`docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}\t{{.Names}}"` 可格式化输出，更清爽。
补充：`docker save -o 镜像.tar 镜像名` 导出镜像、`docker load -i 镜像.tar` 导入镜像，用于离线环境或服务器间迁移。

## 开机自启
标准完整代码：
```powershell
# Docker 服务开机自启
systemctl enable docker

# 容器开机自启（重启后自动拉起）
docker update --restart=always 容器名/容器ID
```

## 数据卷
容器是隔离环境，容器内文件、配置、运行产生的数据都在容器内部，销毁容器会一并丢失。数据卷（volume）是**容器内目录与宿主机目录的映射桥梁**，让数据与容器解耦。

为什么不直接让容器目录指向宿主机目录：容器创建后挂载无法修改，直接指向宿主机目录会与其**强耦合**，切换环境后宿主机路径一旦变化容器就无法工作；容器指向数据卷（逻辑名），数据卷再映射到宿主机目录，宿主机路径变化时只需调整映射关系。

### 数据卷命令
| 命令 | 说明 |
|---|---|
| docker volume create / ls | 创建 / 查看数据卷 |
| docker volume inspect | 查看数据卷详情 |
| docker volume rm / prune | 删除指定数据卷 / 清除未使用的数据卷 |

注意：挂载要在创建容器时通过 `-v` 配置，容器创建后不可修改；创建容器时数据卷不存在会自动创建。

### 挂载语法（-v）
标准完整代码：
```powershell
# 1. 挂载数据卷（虚拟目录）：-v 数据卷名:容器内目录
docker run -d --name nginx -p 80:80 -v html:/usr/share/nginx/html nginx:alpine
# 数据卷实际存放位置：/var/lib/docker/volumes/数据卷名/_data，操作该目录即操作容器内目录

# 2. 挂载本地目录：-v 本地目录:容器内目录
#    本地目录必须以 / 或 ./ 开头，否则会被识别为数据卷名
#    -v mysql:/var/lib/mysql    → 数据卷 mysql
#    -v ./mysql:/var/lib/mysql  → 当前目录下的 mysql 目录（不存在会自动创建）
docker run -d --name mysql -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=123 -e TZ=Asia/Shanghai \
  -v /root/mysql/data:/var/lib/mysql \
  -v /root/mysql/init:/docker-entrypoint-initdb.d \
  -v /root/mysql/conf:/etc/mysql/conf.d \
  mysql:8.0

# 3. 挂载本地文件：-v 本地文件:容器内文件
```
说明：MySQL 镜像会在 `docker-entrypoint-initdb.d` 目录执行初始化 SQL 脚本；`conf.d` 为 MySQL 配置目录。

匿名卷：镜像声明了需要持久化的目录但未指定数据卷时，Docker 会自动创建匿名卷（如 MySQL 的 `/var/lib/mysql`）。`docker inspect 容器名` 的 `Config.Volumes` 部分可看到这些目录，`Mounts` 部分显示实际挂载位置。

## 自定义镜像
部署 Python 等自有应用时，用 Dockerfile 记录打包步骤，`docker build` 自动构建镜像。

### 镜像结构
镜像 = 一堆文件的集合，按操作步骤**分层叠加**（每层为一个 Layer，带唯一 id）。公共层可复用：例如直接基于官方 `python:3.12-slim` 基础镜像，再叠加依赖、源码等层，无需从零准备 Linux 环境。

### Dockerfile 常用指令
| 指令 | 说明 | 示例 |
|---|---|---|
| FROM | 指定基础镜像（必须放在第一行） | FROM python:3.12-slim |
| WORKDIR | 设定应用目录 | WORKDIR /app |
| ENV | 设置环境变量，供后续指令使用 | ENV key value |
| COPY | 拷贝本地文件到镜像指定目录 | COPY pyproject.toml ./ |
| RUN | 执行 shell 命令（一般是安装过程） | RUN uv sync --no-dev |
| EXPOSE | 声明容器运行时监听的端口（提示作用） | EXPOSE 8000 |
| ENTRYPOINT | 容器启动时执行的命令 | ENTRYPOINT ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"] |

标准完整代码（Python 应用 Dockerfile）：
```dockerfile
# 使用 python:3.12-slim 作为基础镜像
FROM python:3.12-slim
# 设定应用目录
WORKDIR /app
# 安装 uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
# 拷贝依赖管理文件并安装依赖
COPY pyproject.toml ./
RUN uv sync --no-dev
# 拷贝源码
COPY src/ ./src/
# 暴露端口
EXPOSE 8000
# 运行命令
ENTRYPOINT ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

构建与运行：
```powershell
docker build -t 镜像名 .   # -t 镜像名（REPOSITORY:TAG，不指定 tag 默认 latest）；. 为 Dockerfile 所在目录
docker run --name 容器名 -p 8000:8000 --env-file .env.prod -d 镜像名   # --env-file 从文件批量加载环境变量
```

## 网络互联
默认 bridge 网络中，容器的虚拟 IP **不固定**，与容器并非永久绑定，代码中不要写死 IP。应在自定义网络中通过**容器名**互联。

### 网络命令
| 命令 | 说明 |
|---|---|
| docker network create / ls | 创建 / 查看网络 |
| docker network rm / prune | 删除指定网络 / 清除未使用网络 |
| docker network connect / disconnect | 容器加入 / 离开网络 |
| docker network inspect | 查看网络详细信息 |

标准完整代码：
```powershell
# 查看容器 IP（确认默认网络 IP 不固定的问题）
docker inspect --format='{{range .NetworkSettings.Networks}}{{println .IPAddress}}{{end}}' mysql

# 创建自定义网络
docker network create 网络名

# 容器加入网络（也可在 docker run 时用 --network 网络名 直接指定）
docker network connect 网络名 mysql

# 同一自定义网络内，可用容器名互相访问，无需记 IP
docker exec -it nginx sh
ping mysql
```

## Docker Compose
一个大型项目常有数十上百个服务，Compose 通过单个 `docker-compose.yml` 文件（YAML）定义一组相互关联的容器，每个容器称为一个 service，可一条命令批量部署。

### docker run 参数 ↔ compose 指令对照
| docker run 参数 | compose 指令 | 说明 |
|---|---|---|
| --name | container_name | 容器名称 |
| -p | ports | 端口映射 |
| -e | environment | 环境变量 |
| -v | volumes | 数据卷配置 |
| --network | networks | 网络 |

标准完整代码（docker-compose.yml）：
```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: mysql
    environment:
      MYSQL_ROOT_PASSWORD: MySQL123
      MYSQL_DATABASE: robot
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:                    # 健康检查：就绪后才会被依赖方启动
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend                # 用该目录下的 Dockerfile 构建镜像
    container_name: backend
    ports:
      - "8000:8000"
    env_file:
      - .env.prod
    depends_on:                     # 启动依赖：等 mysql 健康检查通过后再启动
      mysql:
        condition: service_healthy

  frontend:
    image: nginx:alpine
    container_name: frontend
    ports:
      - "80:80"
    volumes:
      - ./frontend/nginx.conf:/etc/nginx/conf.d/default.conf:ro   # :ro 只读挂载
      - ./frontend/public:/usr/share/nginx/html:ro
    depends_on:
      - backend

volumes:
  mysql_data:                       # 声明命名数据卷，供 services 引用
```

### 基础命令
```powershell
docker compose up -d        # 创建并后台启动所有 service（-f 指定文件，-p 指定 project 名）
docker compose down         # 停止并移除所有容器、网络
docker compose ps           # 列出所有启动的容器
docker compose logs 服务名  # 查看指定服务日志
docker compose stop / start / restart   # 停止 / 启动 / 重启服务
docker compose exec 服务名 命令  # 在运行中的容器内执行命令
```
注意：若宿主机已装同端口的 MySQL/Nginx 等服务，先停掉本机服务再 `docker compose up`，避免端口冲突。

## 参考
- [Docker 官方文档](https://docs.docker.com/)
- [Dockerfile 指令参考](https://docs.docker.com/engine/reference/builder/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
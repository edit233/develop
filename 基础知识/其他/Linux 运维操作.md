---
title: Linux 运维操作
tags: [Linux, 大类, 命令, Shell, vim, 服务器, systemd, 部署, MySQL, Nginx, yum]
created: 2026-08-09
---

## 概述
Linux 运维操作完整指南：目录结构与常用命令、vim 编辑、查找与管道、软件安装与包管理、systemd 服务管理、防火墙、MySQL 安装配置、Nginx 编译安装与反向代理。全部为可复用命令，参数处中文注明。

## 一、目录结构
Linux 是单根树形结构，`/` 是所有目录的顶点（与 Windows 盘符结构不同）。

| 目录 | 含义 |
|---|---|
| /bin | 存放二进制可执行文件 |
| /boot | 存放系统引导时使用的各种文件 |
| /dev | 存放设备文件 |
| /etc | 存放系统配置文件 |
| /home | 存放系统用户的文件 |
| /lib | 存放程序运行所需的共享库和内核模块 |
| /opt | 额外安装的可选应用程序包 |
| /root | 超级用户（root）目录 |
| /sbin | 二进制可执行文件，只有 root 用户才能访问 |
| /tmp | 存放临时文件 |
| /usr | 存放系统应用程序 |
| /var | 存放运行时需要改变数据的文件（如日志） |

路径：
- **绝对路径**：以 `/` 开头，从根目录开始寻找
- **相对路径**：以 `.`（当前目录）或 `..`（上级目录）开头

## 二、命令格式与技巧
```bash
command [-options] [parameter]
```
- 选项支持长格式 `--help` 和短格式 `-h`
- Tab 自动补全；连续两次 Tab 给出操作提示
- 上下箭头快速调出历史命令；`clear` 或 `Ctrl+L` 清屏
- 命令与参数严格区分大小写
- 不确定用法时用 `command --help` 查看帮助文档

## 三、目录操作命令
| 命令 | 作用 | 常用示例 |
|---|---|---|
| ls | 显示目录内容 | `ls -al` 查看所有文件及详细信息（`-a` 含隐藏文件，`-l` 详细信息）；`ll` 是 `ls -l` 的简写 |
| cd | 切换目录 | `cd ..` 上级目录；`cd ~` home 目录（root 为 `/root`）；`cd /usr/local`；`cd -` 回上一次目录 |
| mkdir | 创建目录 | `mkdir -p a/b` 递归创建多层目录 |
| rm | 删除文件/目录 | `rm -rf 目录` 递归强制删除；⚠️ 务必确认目录后再执行，**绝不执行 `rm -rf /`** |

## 四、文件查看命令
| 命令 | 作用 | 常用示例 |
|---|---|---|
| cat | 一次显示全部内容 | `cat -n 文件` 带行号输出 |
| more | 分页显示 | 回车下一行、空格下一屏、`b` 上一屏、`q` 退出 |
| head | 查看文件开头 | `head 文件` 默认 10 行；`head -20 文件` 指定 20 行 |
| tail | 查看文件末尾 | `tail 文件` 默认 10 行；`tail -20 文件`；`tail -f 日志文件` 动态跟踪（`Ctrl+C` 退出） |

## 五、拷贝移动命令
| 命令 | 作用 | 常用示例 |
|---|---|---|
| cp | 复制文件或目录 | `cp 文件 目录/` 复制文件；复制目录必须加 `-r`：`cp -r 目录1 目录2` |
| mv | 移动或改名 | `mv a b`：目标 `b` 是已存在目录则移动，否则改名 |

## 六、打包压缩命令
```bash
tar -zcvf 包名.tar.gz 文件/目录   # 打包并压缩（-c 创建、-z gzip、-v 显示过程、-f 指定包名）
tar -zxvf 包名.tar.gz            # 解压到当前目录（-x 解包）
tar -zxvf 包名.tar.gz -C /目录   # 解压到指定目录（-C）
```
- 后缀 `.tar`：只打包未压缩；`.tar.gz`：打包并压缩

## 七、文本编辑命令（vim）
vim 编辑文件时共三种模式，相互切换：打开文件默认进入**命令模式**；按 `i`/`a`/`o` 进入**插入模式**（可编辑内容，`ESC` 返回命令模式）；命令模式下按 `:` 或 `/` 进入**底行模式**（查找、退出、显示行号）。

命令模式常用指令：
| 指令 | 含义 |
|---|---|
| gg / G | 定位到第一行 / 最后一行 |
| dd / ndd | 删除光标所在行 / 当前行及之后 n 行 |
| u | 撤销操作 |
| i / a / o | 进入插入模式（进入后光标位置不同） |

底行模式常用指令：
| 指令 | 含义 |
|---|---|
| :wq | 保存并退出 |
| :q! | 不保存退出 |
| :set nu / :set nonu | 显示 / 取消行号 |
| :n | 定位到第 n 行（如 :10） |
| /关键词 | 查找内容 |

安装：`yum install vim`（vim 从 vi 发展而来，支持语法着色，实际工作中更常用）

## 八、查找命令
```bash
find 目录 -name "*.txt"      # 在指定目录及子目录下按文件名查找
grep 关键词 文件              # 在文件中查找文本
grep -i 关键词 文件           # 忽略大小写
grep -n 关键词 文件           # 显示匹配行行号
grep -A5 关键词 文件          # 输出匹配行及之后 5 行（-B5 为之前 5 行）

命令1 | 命令2                # 管道：把命令1的输出作为命令2的输入
# 例：ls --help | grep 隐藏   → 在帮助文档中筛选含"隐藏"的参数说明
```

## 九、软件安装方式
| 方式 | 说明 |
|---|---|
| rpm | Red-Hat 软件包管理器，直接安装 .rpm 包，不自动解决依赖 |
| yum | 基于 rpm 的包管理器，自动解决依赖，最常用（仅 RedHat/CentOS/Fedora 可用） |
| 源码编译 | 源码包 → configure → make → make install，可定制安装 |
| 二进制 | 官方编译好的可执行包，解压配置即可用 |

## 十、yum 换国内源
```bash
# 1. 备份系统自带的官方源（重要，新源有问题可恢复）
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup

# 2. 下载阿里云源配置文件（无 curl 可用 wget -O）
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo

# 3. 清理并生成缓存，使更改生效
yum clean all
yum makecache
```
其他镜像源：清华 `https://mirrors.tuna.tsinghua.edu.cn/repo/centos-7.repo`、中科大 `https://mirrors.ustc.edu.cn/repo/centos-7.repo`

## 十一、安装 uv
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh   # 无 curl 用 wget -qO- ... | sh
uv --version                                       # 安装完成后重启 SSH 客户端再执行
```

## 十二、systemctl 服务管理
```bash
systemctl start 服务名      # 启动
systemctl stop 服务名       # 停止
systemctl status 服务名     # 查看状态
systemctl restart 服务名    # 重启
systemctl reload 服务名     # 重载配置（不重启进程）
systemctl enable 服务名     # 开机自启
systemctl disable 服务名    # 取消开机自启
```

## 十三、systemd 脚本模板（Python 应用后台运行）
在 `/etc/systemd/system/` 下新建 `服务名.service`（文件名即服务名），把应用注册为系统服务，即可用 systemctl 统一管理。
```bash
vi /etc/systemd/system/服务名.service
```
```ini
[Unit]
Description=服务描述
After=network.target
Wants=network-online.target

[Service]
# 工作目录（日志会生成在这里）
WorkingDirectory=/root/项目目录
# 启动命令（建议使用绝对路径）
ExecStart=/root/.local/bin/uv run uvicorn src.main:app --host 0.0.0.0 --port 8000
# 日志输出
StandardOutput=append:/root/项目目录/app.log
StandardError=append:/root/项目目录/app.log
# 进程崩溃自动重启
Restart=always
RestartSec=10
# 运行用户
User=root
Group=root
# 环境变量
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
# 进程管理
Type=simple
KillMode=process

[Install]
WantedBy=multi-user.target
```
使用：
```bash
systemctl daemon-reload        # 修改脚本后重新加载才能生效
systemctl start 服务名
systemctl enable 服务名        # 开机自启（谨慎）
```
注意：服务输出日志的目录需有写权限，如 `chmod 755 /root/项目目录 -R`。

## 十四、防火墙（firewalld）
```bash
# 开放端口（--permanent 永久生效）
firewall-cmd --zone=public --add-port=3306/tcp --permanent
# 重新加载
firewall-cmd --reload
# 查看已开放端口
firewall-cmd --zone=public --list-ports
# 直接关闭防火墙（当前 / 永久）
systemctl stop firewalld
systemctl disable firewalld
```

## 十五、安装 MySQL（二进制方式）
```bash
# 1. 检查系统中已安装的 mysql/mariadb（CentOS7 自带 mariadb，与 MySQL 冲突需卸载）
rpm -qa | grep mysql
rpm -qa | grep mariadb
rpm -e --nodeps mariadb-libs-版本号

# 2. 解压安装包并移动到 /usr/local/mysql
tar -zxvf mysql-8.0.30-linux-glibc2.12-x86_64.tar.xz
mv mysql-8.0.30-linux-glibc2.12-x86_64 /usr/local/mysql

# 3. 配置环境变量（追加到 /etc/profile 尾部）
#   export MYSQL_HOME=/usr/local/mysql
#   export PATH=$MYSQL_HOME/bin:$PATH
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
chkconfig --add mysql

# 4. 初始化数据库（执行时日志中会输出 root 临时密码，务必记录下来）
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data

# 5. 启动并登录（服务名可能是 mysql 或 mysqld）
systemctl start mysql
mysql -uroot -p临时密码
```
初始化配置（root 默认仅本机 localhost 可访问）：
```sql
-- 修改 root 本地登录密码
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '新密码';
-- 创建远程访问账号并授权（Windows 客户端或其他服务器访问）
CREATE USER 'root'@'%' IDENTIFIED BY '新密码';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;
```
远程访问还需在防火墙开放 3306 端口。

## 十六、安装 Nginx（源码编译）
```bash
# 1. 安装依赖与 C 编译环境
yum install -y pcre pcre-devel zlib zlib-devel openssl openssl-devel
yum install gcc-c++

# 2. 解压源码包并进入
tar -zxvf nginx-1.20.2.tar.gz
cd nginx-1.20.2

# 3. 配置（生成 Makefile），--prefix 指定安装目录
./configure --prefix=/usr/local/nginx

# 4. 编译并安装
make
make install
```
运行：
```bash
cd /usr/local/nginx
sbin/nginx            # 启动
sbin/nginx -s reload  # 重载配置
sbin/nginx -s stop    # 停止（-s quit 为优雅停止）
ps -ef | grep nginx   # 查看进程确认是否启动
```
注册为 systemd 服务（Nginx 为 fork 型进程，需指定 Type=forking 与 PIDFile）：
```ini
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

## 十七、Nginx 静态资源与反向代理
- **静态资源**：前端页面（html/css/js/image）放在 Nginx 安装目录的 `html` 目录，访问时由 Nginx 直接返回
- **反向代理**：页面请求动态数据时，Nginx 把 `/api/` 路径的请求代理到后端服务，实现前后端分离

标准完整代码（nginx.conf 的 server 部分）：
```nginx
server {
    listen       80;
    server_name  localhost;

    location / {                 # 静态资源
        root   html/public;      # 前端静态资源目录
        index  index.html index.htm;   # 默认首页
    }

    location /api/ {             # 动态接口反向代理到后端
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        # SSE 流式响应支持
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 300s;
    }
}
```
修改配置后 `systemctl reload nginx`（或 `sbin/nginx -s reload`）生效。

## 相关大类
- [[Docker 基础操作]] —— 容器化部署方案（与本篇的裸机部署互补）

## 参考
- [Linux man pages](https://man7.org/linux/man-pages/)
- [systemd.service 文档](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html)
- [Nginx 官方文档](https://nginx.org/en/docs/)
- [uv 安装文档](https://uv.doczh.com/getting-started/installation/)

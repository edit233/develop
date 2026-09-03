---
title: "Nginx 部署实战 - 从本地开发到公网访问"
tags: ["Linux", "Nginx", "SSH", "Git", "部署", "运维"]
created: "2026-09-02"
source: "https://xn--ygr25xpohxwz.com/zero-to-fullstack/lessons/module-3-5/"
---

# Nginx 部署实战 - 从本地开发到公网访问

## 概述

把本地写的网页部署到公网，让任何人都能通过 IP 访问。整条链路：**本地开发 → GitHub 托管 → 服务器 clone → Nginx 托管 → 公网访问**。这是"写代码"和"做了一个真实的东西"之间的关键一步。

## 整体架构

```
你的电脑                  GitHub                   云服务器                浏览器
─────────                ─────────                ─────────              ─────────
index.html  ──push──>    zero-to-tech  ──pull──>  ~/zero-to-tech  ──>   公网 IP
style.css                  仓库                     ↑
script.js                                         Nginx 把这个目录
                                                  当作网站内容
```

核心链路两段：服务器从 GitHub pull 代码 → Nginx 知道网站内容在新目录里。

## 环境准备

| 资源 | 说明 |
|------|------|
| 本地文件 | `~/zero-to-tech/` 下有 `index.html`、`style.css`、`script.js` |
| GitHub 仓库 | 三个文件已 push 到 `zero-to-tech` 仓库 |
| 云服务器 | Ubuntu，Nginx 已跑起来，公网 IP 可访问 |

## 操作步骤

### 1. SSH 登录服务器

```bash
ssh ubuntu@你的公网IP
```

后续所有命令默认在服务器上执行，需要回到本地的会特别标注。

### 2. 确认服务器有 Git

```bash
git --version
```

Ubuntu 云镜像通常预装 Git，看到版本号即可。若报 `command not found`：

```bash
sudo apt update
sudo apt install -y git
```

### 3. 服务器与 GitHub 建立 SSH 信任

**关键点：每台机器都要有自己的 SSH key，Mac 上的不能搬到服务器上用。** 流程与 Mac 上完全一致，只是在 SSH 会话里执行。

**生成 SSH key：**

```bash
ssh-keygen -t ed25519 -C "你的邮箱"
```

连续回车即可。`~/.ssh/` 会生成：
- `id_ed25519`：私钥，不要外传
- `id_ed25519.pub`：公钥，加到 GitHub

**查看并复制公钥：**

```bash
cat ~/.ssh/id_ed25519.pub
```

**添加到 GitHub：** 右上角头像 → Settings → SSH and GPG keys → New SSH key → Title 写机器标识（如 `云服务器-阿里云`） → 粘贴公钥 → 保存

**验证连通：**

```bash
ssh -T git@github.com
```

首次连接输入 `yes` 确认。看到 `Hi xxx! You've successfully authenticated` 即成功。

### 4. Clone 代码到服务器

```bash
cd ~
git clone git@github.com:你的用户名/zero-to-tech.git
```

用 SSH 地址（不是 HTTPS），这样后续 `git pull` 不需要每次输凭证。clone 完后 `~/zero-to-tech/` 目录下有完整项目文件。

### 5. 修改 Nginx 配置

Nginx 默认网站内容在 `/var/www/html/`，需要改为 clone 下来的目录。

**编辑默认站点配置：**

```bash
sudo vim /etc/nginx/sites-enabled/default
```

**找到 `root` 那一行，改为：**

```
root /home/ubuntu/zero-to-tech;
```

> 如果 `index` 那行写的是 `index.html index.htm index.nginx-debian.html;`，可以简化为 `index.html;`，因为我们只用 `index.html`。

**校验配置语法：**

```bash
sudo nginx -t
```

看到 `syntax is ok` 和 `test is successful` 才能继续。**不通过不要 reload。**

**重新加载 Nginx：**

```bash
sudo systemctl reload nginx
```

### 6. 解决 403 权限问题（关键坑）

刷新浏览器大概率会看到 **403 Forbidden**。原因是：

> Nginx 以 `www-data` 用户身份读文件，而 `/home/ubuntu/` 目录权限默认不允许其他用户进入。

`ls -ld /home/ubuntu/` 会看到类似 `drwxr-x---`，最后三位 `---` 意味着 others 没有任何权限。

**修复：**

```bash
sudo chmod o+x /home/ubuntu
```

拆解：
- `o` = others（非属主、非属主组的用户，包括 `www-data`）
- `x` = 能穿过这个目录（不是能列出内容）

这是**最小授权**：`www-data` 能穿过 `/home/ubuntu` 拿到网页文件，但无法 `ls` 你的家目录。只做一次，后续不用再碰。

### 7. 验证

浏览器刷新公网 IP → 看到页面，点击按钮有响应 → 部署成功。

### 8. 完整更新流程（肌肉记忆）

以后每次改代码，三段操作：

```bash
# ① 本地（Mac 终端）
cd ~/zero-to-tech
git add .
git commit -m "写清楚这次改了什么"
git push
```

```bash
# ② 服务器（SSH 会话）
cd ~/zero-to-tech
git pull
```

```
# ③ 浏览器
刷新
```

这就是最朴素的**持续部署**。后续可自动化为：GitHub 推送 → 服务器自动 pull（CI/CD）。

## Nginx 配置核心字段

| 字段 | 作用 |
|------|------|
| `server` | 定义一个虚拟主机（站点）配置块 |
| `listen` | 监听的端口（通常 80） |
| `root` | 网站文件的根目录 |
| `index` | 默认首页文件名 |
| `server_name` | 域名/IP 匹配 |
| `location` | URL 路径匹配规则 |

## 常见问题排查

| 问题 | 原因与解决 |
|------|-----------|
| 浏览器还是 Nginx 默认欢迎页 | 浏览器缓存，`Command + Shift + R` 强刷或用无痕窗口；检查 `root` 是否改对、是否 reload 了 |
| `nginx -t` 报错 | 漏了行尾分号、路径拼错，按错误提示修正后重新 test |
| chmod 改了还是 403 | 再跑 `ls -ld /home/ubuntu` 确认最后一位是 `x`（`drwxr-x--x`）；还不行就强制刷新浏览器 |
| `git pull` 报冲突 | 服务器上手动改了文件。原则：**服务器不要手改文件**，所有改动在本地做，push/pull 同步 |

恢复服务器本地改动：

```bash
cd ~/zero-to-tech
git checkout .   # 丢弃未提交的改动
git pull
```

## 关于 HTTPS 与 SSH 选择

| 方式 | 特点 |
|------|------|
| HTTPS (`https://github.com/...`) | Public 仓库无需凭证；Private 仓库每次 push/pull 要输用户名 + token |
| SSH (`git@github.com:...`) | 配过一次 key 后一劳永逸，不分公私 |

统一用 SSH：配一次不管仓库公私都能用，与本地 Mac 流程一致。

---

*来源：[李勃老师 · 零到全栈 · 模块 3.5](https://xn--ygr25xpohxwz.com/zero-to-fullstack/lessons/module-3-5/)*
*最后更新：2026-09-02*

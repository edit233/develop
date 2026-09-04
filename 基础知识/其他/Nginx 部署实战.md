---
title: "Nginx 部署实战"
tags: ["Nginx", "部署"]
created: "2026-09-02"
---

# Nginx 部署实战

## 概述

Nginx 将本地网页部署到公网的核心流程：配置站点 → 校验语法 → 解决权限 → 重载生效。

## 修改 Nginx 配置

编辑默认站点配置：

```bash
sudo vim /etc/nginx/sites-enabled/default
```

找到 `root` 那一行，改为网站文件所在目录：

```
root /home/ubuntu/zero-to-tech;
```

> 如果 `index` 那行写的是 `index.html index.htm index.nginx-debian.html;`，可以简化为 `index.html;`。

## 校验配置语法

```bash
sudo nginx -t
```

看到 `syntax is ok` 和 `test is successful` 才能继续。**不通过不要 reload。**

## 重新加载 Nginx

```bash
sudo systemctl reload nginx
```

## 解决 403 权限问题（关键坑）

刷新浏览器大概率会看到 **403 Forbidden**。原因是：

> Nginx 以 `www-data` 用户身份读文件，而网站目录上级目录的权限默认不允许其他用户进入。

`ls -ld /home/ubuntu/` 会看到类似 `drwxr-x---`，最后三位 `---` 意味着 others 没有任何权限。

**修复：**

```bash
sudo chmod o+x /home/ubuntu
```

拆解：
- `o` = others（非属主、非属主组的用户，包括 `www-data`）
- `x` = 能穿过这个目录（不是能列出内容）

这是**最小授权**：`www-data` 能穿过 `/home/ubuntu` 拿到网页文件，但无法 `ls` 你的家目录。只做一次，后续不用再碰。

## 验证

浏览器刷新公网 IP → 看到页面，点击按钮有响应 → 部署成功。

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
| 浏览器还是 Nginx 默认欢迎页 | 浏览器缓存，强刷或用无痕窗口；检查 `root` 是否改对、是否 reload 了 |
| `nginx -t` 报错 | 漏了行尾分号、路径拼错，按错误提示修正后重新 test |
| chmod 改了还是 403 | 再跑 `ls -ld /home/ubuntu` 确认最后一位是 `x`（`drwxr-x--x`）；还不行就强制刷新浏览器 |

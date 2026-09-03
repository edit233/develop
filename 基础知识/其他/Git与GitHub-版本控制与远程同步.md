---
title: "Git 与 GitHub - 版本控制与远程同步"
tags: ["Git", "GitHub", "版本控制", "SSH", "协作"]
created: "2026-09-02"
source: "https://xn--ygr25xpohxwz.com/zero-to-fullstack/lessons/"
---

# Git 与 GitHub - 版本控制与远程同步

## 概述

Git 解决"本地版本管理"——在改动前后保留清晰历史，随时可以回看、比较、回退。GitHub 解决"远程同步"——给本地仓库加一份网络上的可信副本，支持备份、协作、部署。两者组合形成完整的代码管理链路。

## Git 基础：本地版本控制

### 为什么要用 Git

没有版本管理时常见问题：改了代码页面崩了、记不清改了什么、想回到上一版但没有回退点。AI 写代码同样需要——第一版能跑，第二版优化后崩了，没有可靠保存就回不去。

> **核心价值**：在改动前后保留清晰的历史，让你随时可以回看、比较、回退。

### 核心概念

| 概念 | 说明 |
|------|------|
| 仓库（repository） | Git 管理的最小单位是一个目录，`git init` 后该目录成为仓库 |
| commit（提交） | 记录一次有意义的改动，包含文件快照、时间、作者、提交说明 |
| 暂存区（staging area） | `git add` 后文件进入暂存区，为下一次 commit 做准备 |
| 工作区 | 你实际编辑文件的目录 |
| `.gitignore` | 告诉 Git 哪些文件/目录不需要跟踪 |

### 5 步初始化流程

**1）确认 Git 已安装**

```bash
git --version
# 看到 git version 2.x.x 即可
# macOS 未安装会引导安装 Command Line Tools，也可用 Homebrew
```

**2）配置提交身份（每台电脑一次）**

```bash
# 查看是否已配置
git config --global user.name
git config --global user.email

# 首次配置
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
```

**3）初始化仓库**

```bash
cd ~/zero-to-tech
git init
git status    # 未跟踪的文件显示为 Untracked files
```

**4）创建 .gitignore**

```bash
# 在项目根目录创建 .gitignore，写入需要忽略的文件
.DS_Store
```

关键点：
- `.gitignore` 本身应该提交（它是项目规则）
- `.git` 目录不需要写进 `.gitignore`（Git 自动管理）

**5）第一次提交**

```bash
git add .                        # 把所有改动加入暂存区（排除 .gitignore 忽略的文件）
git status                       # 确认文件在 "Changes to be committed" 中
git commit -m "第一次提交"        # 创建第一个版本点
```

### 日常提交节奏

每次有意义的改动都提交，小步提交比大包提交更安全：

```bash
git add .
git commit -m "修改首页标题文案"
```

### 常见误区

| 误区 | 正确做法 |
|------|---------|
| 只有大改动才值得提交 | 只要改动有意义就值得提交，小步更安全 |
| 提交说明以后再补 | 当时写最好，后补容易失真 |
| `.gitignore` 可有可无 | 越早建立越干净，后续协作越省事 |

## GitHub：远程同步

### 为什么需要远程仓库

本地代码只有本机一份，电脑损坏或更换时迁移成本高，多人协作没有统一同步点，部署时无法稳定拉取同一份代码。远程仓库 = 网络上的可信副本。

### 完整同步链路

```
本地仓库  ──push──>  GitHub 仓库  ──pull──>  其他机器 / 服务器
```

### 5 步建立远程同步

**1）在 GitHub 创建空仓库**

- 仓库名：与本地项目同名（如 `zero-to-tech`）
- 不勾选 "Initialize this repository with a README"（本地已有文件，空仓库最利于首次同步）
- 创建后复制 SSH 地址：`git@github.com:你的用户名/zero-to-tech.git`

**2）配置 SSH 信任（每台机器一次）**

生成密钥对：

```bash
ssh-keygen -t ed25519 -C "你的邮箱"
# 连续回车使用默认值
# 生成 ~/.ssh/id_ed25519（私钥，不外传）和 ~/.ssh/id_ed25519.pub（公钥）
```

查看并复制公钥：

```bash
cat ~/.ssh/id_ed25519.pub
# 复制整行内容
```

添加到 GitHub：Settings → SSH and GPG keys → New SSH key → 粘贴公钥 → 保存

验证连通：

```bash
ssh -T git@github.com
# 看到认证成功提示即可
```

> SSH 一时配不通不要卡死，可临时用 HTTPS 先跑通同步链路。

**3）关联本地与远程仓库**

```bash
cd ~/zero-to-tech
git remote add origin git@github.com:你的用户名/zero-to-tech.git
git remote -v    # 验证关联是否成功
```

`origin` 是远程仓库的约定命名。

**4）第一次 push**

```bash
git branch        # 确认当前分支名（main 或 master）

git push -u origin main    # 或 origin master
# -u 建立本地分支与远程分支的跟踪关系，之后只需 git push
```

**5）在 GitHub 页面验证**

打开仓库页面，确认能看到 `index.html`、`style.css`、`script.js`、`.gitignore`。

### 持续同步的标准流程

```bash
# 推送本地改动到 GitHub
git add .
git commit -m "写清楚这次改了什么"
git push

# 从 GitHub 拉取远程更新
git pull
```

## 完整生命周期：本地 → GitHub → 服务器

三段操作，这就是最朴素的持续部署：

```bash
# ① 本地改代码
git add .
git commit -m "改了什么"
git push

# ② 服务器拉取
cd ~/zero-to-tech
git pull

# ③ 浏览器刷新验证
```

## GitHub Desktop

不想记命令时可以用 GitHub Desktop（官方图形工具）：可视化查看改动、图形化 Commit、一键 Push。与命令行操作同一仓库，可随时切换。

## SSH vs HTTPS 选择

| 方式 | 特点 |
|------|------|
| SSH (`git@github.com:...`) | 配一次 key 一劳永逸，不分公私，推荐 |
| HTTPS (`https://github.com/...`) | Public 仓库无需凭证；Private 仓库每次要输 token |

## 关键检查点

完成学习后应能做到：
- [ ] `zero-to-tech` 已 `git init` 并完成至少一次 commit
- [ ] 已配置 `user.name` / `user.email`
- [ ] 已创建 `.gitignore` 忽略 `.DS_Store`
- [ ] 理解 `git add`、`git commit`、`git status` 的关系
- [ ] GitHub 仓库已创建并关联
- [ ] SSH 信任已建立（`ssh -T git@github.com` 验证通过）
- [ ] 第一次 `push` 成功，GitHub 页面能看到文件
- [ ] 能说出 push / pull / commit / add 各自做什么

---

*来源：[李勃老师 · 零到全栈 · 模块 3.3 & 3.4](https://xn--ygr25xpohxwz.com/zero-to-fullstack/lessons/)*
*最后更新：2026-09-02*

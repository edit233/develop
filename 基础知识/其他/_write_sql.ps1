import os

content = """---
title: "SQL 速查手册"
tags: ["SQL", "数据库", "速查手册"]
created: "2026-09-05"
---

# SQL 速查手册

> 给「学过但忘了」的人。10 秒定位，30 秒回忆。

---

## 场景索引

| 我想... | 去哪看 |
|--------|------|
| 查所有数据或指定字段 | → 基本查询 |
| 按条件筛选行 | → WHERE 条件查询 |
| 模糊匹配名字 | → LIKE 模糊查询 |
| 去重查看不重复值 | → DISTINCT 去重 |
| 统计总数/平均/最大最小 | → 聚合函数 |
| 按部门/类别统计人数 | → GROUP BY 分组 |
| 分组后再筛选 | → HAVING 分组后过滤 |
| 按薪资/日期排序 | → ORDER BY 排序 |
| 查前 N 条或分页 | → 分页查询 |
| 插入一条/批量数据 | → INSERT 插入 |
| 修改已有数据 | → UPDATE 修改 |
| 删除数据 | → DELETE 删除 |
| 建一张新表 | → 建表模板 |
| 增删改表字段 | → 修改表结构 |
| 两表关联查交集 | → INNER JOIN |
| 查左表全部 + 右表匹配 | → LEFT JOIN |
| 查 A 有但 B 没有的数据 | → LEFT JOIN + IS NULL |
| 自己跟自己关联（上下级） | → 自连接 |
| 合并两个查询结果 | → UNION 联合查询 |
| 子查询返回单个值比较 | → 标量子查询 |
| 子查询返回多个值用 IN | → 列子查询 |
| 子查询当临时表用 | → 表子查询 |
| 同时更新多条关联数据 | → 事务 |
| 银行转账/扣库存等原子操作 | → 事务 |

---

## 一、我想查数据

> 所有 SELECT 用法：条件筛选、聚合统计、分组排序、分页。

### 基本查询

**模板：**

```sql
SELECT 字段1, 字段2 FROM 表名;
```

**例子：** 查所有员工的姓名和入职日期

```sql
SELECT 姓名, 入职日期 FROM 员工表;
```

**记住：** 用 `SELECT 具体字段`，别用 `SELECT *`。

---

### DISTINCT 去重

**模板：**

```sql
SELECT DISTINCT 字段 FROM 表名;
```

**例子：** 查所有不重复的职位

```sql
SELECT DISTINCT 职位 FROM 员工表;
```

---

### WHERE 条件查询

**模板：**

```sql
SELECT * FROM 表名 WHERE 条件;
```

**常用条件：**

```sql
-- 比较
WHERE 薪资 > 15000
WHERE 薪资 >= 15000 AND 性别 = 1

-- 范围（闭区间）
WHERE 入职日期 BETWEEN '2020-01-01' AND '2023-12-31'

-- 列表匹配（OR 的简写）
WHERE 职位 IN (1, 2, 3)

-- 空值判断（不能用 = NULL）
WHERE 职位 IS NULL
```

**例子：** 查薪资 15000 以上且在职的员工

```sql
SELECT * FROM 员工表 WHERE 薪资 > 15000 AND 状态 = '在职';
```

**记住：** `NULL` 用 `IS NULL` / `IS NOT NULL`，不能用 `=` 或 `!=`。

---

### LIKE 模糊查询

**模板：**

```sql
SELECT * FROM 表名 WHERE 字段 LIKE '模式';
```

**模式：** `%` 匹配任意多个字符，`_` 匹配恰好一个字符

```sql
WHERE 姓名 LIKE '张%'      -- 以「张」开头
WHERE 姓名 LIKE '%张%'     -- 包含「张」
WHERE 姓名 LIKE '张_'      -- 「张」+ 恰好一个字符
```

**记住：** `%` 放两边是包含匹配，放末尾是前缀匹配。

---

### 聚合函数

**模板：**

```sql
SELECT COUNT(*) AS 总数,
       AVG(字段) AS 平均值,
       MAX(字段) AS 最大值,
       MIN(字段) AS 最小值,
       SUM(字段) AS 总和
FROM 表名;
```

**例子：** 统计员工总数和平均薪资

```sql
SELECT COUNT(*) AS 员工数, AVG(薪资) AS 平均薪资 FROM 员工表;
```

**记住：** 聚合函数自动忽略 NULL 值。`COUNT(*)` 统计所有行（含 NULL）。

---

### GROUP BY 分组

**模板：**

```sql
SELECT 分组字段, COUNT(*)
FROM 表名
WHERE 条件          -- 可选：分组前过滤
GROUP BY 分组字段
HAVING 条件;        -- 可选：分组后过滤
```

**例子：** 按部门统计人数，只看人数超过 5 人的部门

```sql
SELECT 部门, COUNT(*) AS 人数
FROM 员工表
GROUP BY 部门
HAVING COUNT(*) > 5;
```

**记住：** `WHERE` 在分组前过滤（不能用聚合函数），`HAVING` 在分组后过滤（可以用聚合函数）。

---

### ORDER BY 排序

**模板：**

```sql
SELECT * FROM 表名 ORDER BY 字段 ASC;   -- 升序（默认）
SELECT * FROM 表名 ORDER BY 字段 DESC;  -- 降序
```

**例子：** 按薪资降序排列

```sql
SELECT * FROM 员工表 ORDER BY 薪资 DESC;
```

**记住：** 多字段排序先写主排序键，再写次排序键。

---

### 分页查询

**模板：**

```sql
SELECT * FROM 表名 LIMIT 起始索引, 每页条数;
```

**公式：** 起始索引 = (页码 - 1) x 每页条数

**例子：** 第 3 页，每页 10 条

```sql
SELECT * FROM 员工表 LIMIT 20, 10;  -- 索引从 0 开始，第3页起始 = (3-1)*10 = 20
```

**记住：** `LIMIT` 是 MySQL/PostgreSQL 方言。SQL Server 用 `TOP`，Oracle 用 `ROWNUM`。

---

## 二、我想改数据

> INSERT / UPDATE / DELETE，增删改表里的数据。

### INSERT 插入

**模板：**

```sql
-- 单条插入
INSERT INTO 表名 (字段1, 字段2) VALUES (值1, 值2);

-- 批量插入
INSERT INTO 表名 (字段1, 字段2) VALUES (值1, 值2), (值3, 值4);
```

**例子：** 插入一个新员工

```sql
INSERT INTO 员工表 (姓名, 薪资, 入职日期) VALUES ('张三', 15000, '2024-01-15');
```

**记住：** 字段顺序和值一一对应。字符串和日期用引号。

---

### UPDATE 修改

**模板：**

```sql
UPDATE 表名 SET 字段1 = 值1, 字段2 = 值2 WHERE 条件;
```

**例子：** 把张三的薪资改为 18000

```sql
UPDATE 员工表 SET 薪资 = 18000 WHERE 姓名 = '张三';
```

**记住：** **必须加 WHERE**，不加会更新全表。

---

### DELETE 删除

**模板：**

```sql
DELETE FROM 表名 WHERE 条件;
```

**例子：** 删除离职员工

```sql
DELETE FROM 员工表 WHERE 状态 = '离职';
```

**记住：** **必须加 WHERE**，不加会删除全表。`DELETE` 不重置自增计数器；`TRUNCATE TABLE` 会重置。

---

## 三、我想建表改表

> DDL：建库、建表、改表结构。

### 建表模板

```sql
CREATE TABLE 表名 (
    id         INT PRIMARY KEY AUTO_INCREMENT,     -- 主键自增
    字段1      VARCHAR(50) NOT NULL,                -- 必填字段
    字段2      INT DEFAULT 0,                       -- 默认值
    字段3      DATE,                                -- 日期
    唯一字段   VARCHAR(20) UNIQUE,                  -- 唯一约束
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP  -- 公共字段
) COMMENT '表注释';
```

**例子：** 建一张员工表

```sql
CREATE TABLE 员工表 (
    id         INT PRIMARY KEY AUTO_INCREMENT,
    姓名       VARCHAR(20) NOT NULL,
    薪资       DOUBLE(10,2) DEFAULT 0,
    入职日期   DATE,
    部门       VARCHAR(50),
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) COMMENT '员工信息表';
```

**记住：** 主键统一用 `INT UNSIGNED AUTO_INCREMENT`。字段都加 `COMMENT`。

---

### 修改表结构

```sql
ALTER TABLE 表名 ADD 新字段名 类型;                    -- 新增列
ALTER TABLE 表名 MODIFY 字段名 新类型;                  -- 改类型（不改名）
ALTER TABLE 表名 CHANGE 旧字段名 新字段名 新类型;       -- 改名 + 改类型
ALTER TABLE 表名 DROP 字段名;                           -- 删列
RENAME TABLE 表名 TO 新表名;                            -- 改表名
DROP TABLE IF EXISTS 表名;                             -- 删表
```

**记住：** `DROP` 会丢失数据，操作前先备份。

---

### 查看表结构

```sql
SHOW TABLES;                    -- 列出所有表
DESC 表名;                      -- 查看字段结构
SHOW CREATE TABLE 表名;         -- 查看建表 SQL
```

---

### 五大约束速查

| 约束 | 关键字 | 示例 |
|------|--------|------|
| 非空 | `NOT NULL` | `name VARCHAR(10) NOT NULL` |
| 唯一 | `UNIQUE` | `username VARCHAR(20) UNIQUE` |
| 主键 | `PRIMARY KEY` | `id INT PRIMARY KEY` |
| 默认值 | `DEFAULT` | `gender CHAR(1) DEFAULT '男'` |
| 外键 | `FOREIGN KEY` | 见下方 |

---

### 数据类型速查

| 场景 | 类型 | 示例 |
|------|------|------|
| 整数 | `INT` / `TINYINT UNSIGNED` | id / 年龄 |
| 小数 | `DOUBLE(m,n)` | 薪资 `DOUBLE(10,2)` |
| 定长字符串 | `CHAR(n)` | 手机号 `CHAR(11)` |
| 变长字符串 | `VARCHAR(n)` | 姓名 `VARCHAR(50)` |
| 日期 | `DATE` | 出生日期 `DATE` |
| 日期时间 | `DATETIME` | 创建时间 `DATETIME` |

---

## 四、我想关联多张表

> JOIN、子查询、联合查询——把多张表的数据拉到一起。

### INNER JOIN（内连接）

**模板：**

```sql
SELECT A.字段, B.字段
FROM 表A A
INNER JOIN 表B B ON A.关联字段 = B.关联字段;
```

**例子：** 查所有员工及其部门名称

```sql
SELECT 员工.姓名, 部门.名称
FROM 员工表 员工
INNER JOIN 部门表 部门 ON 员工.部门ID = 部门.id;
```

**记住：** 内连接只返回两边都匹配的记录。

---

### LEFT JOIN（左外连接）

**模板：**

```sql
SELECT A.字段, B.字段
FROM 表A A
LEFT JOIN 表B B ON A.关联字段 = B.关联字段;
```

**例子：** 查所有部门及其员工（包括没有员工的部门）

```sql
SELECT 部门.名称, 员工.姓名
FROM 部门表 部门
LEFT JOIN 员工表 员工 ON 部门.id = 员工.部门ID;
```

**记住：** 左表全部保留，右表不匹配的填 NULL。

---

### LEFT JOIN + IS NULL（查 A 有但 B 没有的）

**模板：**

```sql
SELECT A.*
FROM 表A A
LEFT JOIN 表B B ON A.关联字段 = B.关联字段
WHERE B.关联字段 IS NULL;
```

**例子：** 查没有分配部门的员工

```sql
SELECT 员工.*
FROM 员工表 员工
LEFT JOIN 部门表 部门 ON 员工.部门ID = 部门.id
WHERE 部门.id IS NULL;
```

---

### 自连接

**模板：**

```sql
SELECT A.字段 AS 下级, B.字段 AS 上级
FROM 表名 A
LEFT JOIN 表名 B ON A.上级字段 = B.id;
```

**例子：** 查员工及其上级

```sql
SELECT A.姓名 AS 员工, B.姓名 AS 上级
FROM 员工表 A
LEFT JOIN 员工表 B ON A.上级ID = B.id;
```

**记住：** 自连接就是同一张表取两个别名。

---

### UNION 联合查询

**模板：**

```sql
SELECT 字段1, 字段2 FROM 表A WHERE 条件1
UNION
SELECT 字段1, 字段2 FROM 表B WHERE 条件2;
```

**例子：** 查岗位 1 和薪资超过 10000 的员工（合并去重）

```sql
SELECT 姓名, 手机号 FROM 员工表 WHERE 岗位 = 1
UNION
SELECT 姓名, 手机号 FROM 员工表 WHERE 薪资 > 10000;
```

**记住：** `UNION` 自动去重，`UNION ALL` 保留重复。两个 SELECT 的列数和类型必须一致。

---

### 标量子查询

子查询返回**单个值**，用比较运算符。

```sql
-- 模板
SELECT * FROM 表名 WHERE 字段 = (SELECT MAX(字段) FROM 表名);
```

**例子：** 查薪资最高的员工

```sql
SELECT * FROM 员工表 WHERE 薪资 = (SELECT MAX(薪资) FROM 员工表);
```

---

### 列子查询

子查询返回**多个值**，用 `IN`。

```sql
-- 模板
SELECT * FROM 表A WHERE 字段 IN (SELECT 字段 FROM 表B WHERE 条件);
```

**例子：** 查技术部和市场部的所有员工

```sql
SELECT * FROM 员工表
WHERE 部门ID IN (SELECT id FROM 部门表 WHERE 名称 IN ('技术部', '市场部'));
```

---

### 表子查询（派生表）

子查询返回**多行多列**，作为临时表。

```sql
-- 模板
SELECT A.*
FROM 表名 A,
     (SELECT 分组字段, MAX(数值字段) AS 最大值
      FROM 表名 GROUP BY 分组字段) B
WHERE A.分组字段 = B.分组字段 AND A.数值字段 = B.最大值;
```

**例子：** 查每个部门薪资最高的员工

```sql
SELECT A.*
FROM 员工表 A,
     (SELECT 部门, MAX(薪资) AS 最高薪资
      FROM 员工表 GROUP BY 部门) B
WHERE A.部门 = B.部门 AND A.薪资 = B.最高薪资;
```

---

## 五、我想处理事务

> 保证一组操作要么全成功，要么全失败。

### 事务模板

```sql
START TRANSACTION;               -- 开启事务

-- 执行多条 DML
UPDATE 表A SET ... WHERE ...;
INSERT INTO 表B ...;
UPDATE 表C SET ... WHERE ...;

COMMIT;                          -- 全部成功 -> 提交
-- 或
ROLLBACK;                        -- 任一失败 -> 回滚
```

**例子：** 给员工涨薪 + 记录日志（原子操作）

```sql
START TRANSACTION;

UPDATE 员工表 SET 薪资 = 薪资 + 2000 WHERE id = 5;
INSERT INTO 操作日志(员工ID, 操作, 时间) VALUES (5, '涨薪', NOW());

COMMIT;  -- 成功则提交
-- 或
ROLLBACK;  -- 失败则全部撤销
```

**记住：** MySQL 默认自动提交（每条 DML 立即生效）。必须手动 `START TRANSACTION` 才能回滚。

---

### ACID 速记

| 特性 | 一句话 |
|------|--------|
| 原子性 Atomicity | 要么全做，要么全不做 |
| 一致性 Consistency | 完成后数据状态合法 |
| 隔离性 Isolation | 并发事务互不干扰 |
| 持久性 Durability | 提交后数据永久保存 |

---

### 外键约束操作

```sql
-- 建表时加外键
CREATE TABLE 订单表 (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES 用户表(id)
);

-- 建表后加外键
ALTER TABLE 订单表
ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES 用户表(id);

-- 删除外键
ALTER TABLE 订单表 DROP FOREIGN KEY fk_user;
```

**记住：** 企业开发中优先用「逻辑外键」（代码层面维护关联），很少用物理外键。
"""

path = os.path.join('D:', os.sep, 'Study', 'Note', 'develop', '基础知识', '其他', 'SQL 速查手册.md')
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Written:', path)
print('Size:', len(content), 'chars')

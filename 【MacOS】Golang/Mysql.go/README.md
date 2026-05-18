# `Mysql.go`

![Jobs倾情奉献](https://picsum.photos/1500/400 "Jobs出品，必属精品")

[toc]

---

## 🔥 <font id=前言>前言</font>

这里记录 [**Golang**](https://go.dev/) 操作 [**MySQL**](https://www.mysql.com) 示例工程的基础依赖整理命令，适合在本地验证数据库增删改查前先清理项目依赖。

## 一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 新建 Go + MySQL 示例工程。
- 调整 `go.mod` 后清理多余依赖。
- 模块缓存异常时重新下载依赖。

## 二、常用命令 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 整理 `go.mod` 和 `go.sum`：

  ```shell
  go mod tidy
  ```

- 清理本机模块缓存：

  ```shell
  go clean -modcache
  ```

## 三、注意事项 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- `go clean -modcache` 会删除已下载模块缓存，后续构建会重新联网下载。
- 如果项目还需要 MySQL 驱动，可参考同目录 `Gorm.go` 的依赖安装命令。
- 数据库地址、账号、密码不要写入公共 README 或提交到仓库。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

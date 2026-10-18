# `Gorm.go`

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#jobs-toc-heading-1)
- [一、适用场景](#jobs-toc-heading-2)
- [二、常用命令](#jobs-toc-heading-3)
- [三、注意事项](#jobs-toc-heading-4)

</details>
<!-- jobs-toc:end -->

---

## <span id="jobs-toc-heading-1" data-jobs-toc="v2">🔥 <font id=前言>前言</font></span><!-- jobs-toc:heading-end -->

这里记录 [**Golang**](https://go.dev/) 使用 [**GORM**](https://gorm.io/) 操作 [**MySQL**](https://www.mysql.com) 的最小依赖准备命令，适合在新建示例工程或修复依赖时快速查阅。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 新建 Go + GORM + MySQL 示例工程。
- 整理 `go.mod`，移除未使用依赖。
- 清理本机 Go 模块缓存后重新拉取依赖。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、常用命令 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 整理当前项目依赖：

  ```shell
  go mod tidy
  ```

- 清理已下载的模块缓存：

  ```shell
  go clean -modcache
  ```

- 安装 MySQL 驱动：

  ```shell
  go get -u gorm.io/driver/mysql
  ```

- 安装 GORM：

  ```shell
  go get -u gorm.io/gorm
  ```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、注意事项 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- `go clean -modcache` 会清理 `$GOPATH/pkg/mod` 下已下载依赖，下一次构建会重新下载。
- 执行 `go get -u` 前，建议先确认当前工程的 Go 版本和依赖兼容性。
- 这些命令只整理 Go 依赖，不负责创建数据库、表结构或连接配置。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

# `【MacOS】GoProject.sh`

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#jobs-toc-heading-1)
- [一、适用场景](#jobs-toc-heading-2)
- [二、目录结构](#jobs-toc-heading-3)
- [三、执行前检查](#jobs-toc-heading-4)
- [四、运行方式](#jobs-toc-heading-5)
  - [4.1、双击运行](#jobs-toc-heading-6)
  - [4.2、终端运行](#jobs-toc-heading-7)
- [五、操作流程](#jobs-toc-heading-8)
- [六、风险说明](#jobs-toc-heading-9)
- [七、日志文件](#jobs-toc-heading-10)
- [八、常见问题](#jobs-toc-heading-11)
  - [8.1、提示命令不存在](#jobs-toc-heading-12)
  - [8.2、提示权限不足](#jobs-toc-heading-13)
  - [8.3、双击后没有继续执行](#jobs-toc-heading-14)
- [九、未执行声明](#jobs-toc-heading-15)

</details>
<!-- jobs-toc:end -->

---

## <span id="jobs-toc-heading-1" data-jobs-toc="v2">🔥 <font id=前言>前言</font></span><!-- jobs-toc:heading-end -->

创建独立的 [**Go**](https://go.dev/) module 和 [**Gin**](https://gin-gonic.com/) `/ping` 示例，选择后再下载依赖、校验或运行。

新建所选父目录下的工程；拒绝已有目标，不修改 `GOPATH` 或 Shell 启动配置。

| 入口速览 | 实际行为 |
| --- | --- |
| 操作顺序 | 输入父目录 → 工程名 / module / 文件名 → 生成骨架 → 可选 `go mod tidy`、`go test`、`go run`。 |
| 交互 | 自述回车继续；安装、升级、下载和运行均回车跳过、非空执行。 |
| 依赖 | Homebrew → Go / gofmt；Gin 依赖在选择下载后由 Go module 解析。 |

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 创建独立的 [**Go**](https://go.dev/) module 和 [**Gin**](https://gin-gonic.com/) `/ping` 示例，选择后再下载依赖、校验或运行。
- 希望通过可重复运行的 Shell 脚本减少手工命令遗漏。
- 需要结合终端日志定位环境、路径或第三方工具问题。

脚本统一由 macOS 预置的 `/bin/zsh` 执行。双击或直接执行脚本即可；显式指定解释器时使用 `zsh`，不要使用 `bash` 或 `sh`。运行后先显示内置自述，确认后才进入业务；无法读取确认输入时会退出。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录结构 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```text
【MacOS】GoProject.sh/
├── 【MacOS】GoProject.sh
└── README.md
```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 确认当前系统为 MacOS，并已安装脚本实际调用的工具。
- 确认脚本路径、工程目录、输入文件和当前 Git 工作区正确。
- 打开主脚本检查其中的业务命令，不理解的操作不要直接执行。
- 涉及安装、更新或升级时，以脚本终端提示为准；直接回车应表示跳过。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">4.1、双击运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在 Finder 中打开当前目录并双击 `【MacOS】GoProject.sh`。阅读终端自述后按回车继续，按 `Ctrl+C` 取消。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">4.2、终端运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在当前 README 所在目录运行：

```shell
zsh ./【MacOS】GoProject.sh
```

## <span id="jobs-toc-heading-8" data-jobs-toc="v2">五、操作流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、展示写在源码内的自述，回车确认后初始化日志。

2、复用健康 Homebrew 与 Go；安装、修复或升级均回车跳过、非空输入执行，缺失依赖未补齐则停止。

3、输入工程父目录（默认脚本旁 `GeneratedProjects`）、文件夹名（默认 `Test`）、module 路径（默认 `example.com/demo`）及源码名（默认 `main.go`）。

4、拒绝已存在的工程目录；创建 `go.mod`、Gin 模板与脱敏后的 `localGoEnvInfo.md`，仅监听 `127.0.0.1:8080`。

5、选择下载依赖时先执行 `go mod tidy` 再 `go test ./...`；两者成功后才可选择前台运行，`Ctrl+C` 停止服务。

6、已有 `code` 命令时可选打开编辑器；不自动安装 IDE 或旧 `govendor` 工具。

## <span id="jobs-toc-heading-9" data-jobs-toc="v2">六、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->


- 依赖下载使用当前 Go 的 `GOPROXY`；版本由首次解析结果记录在工程 `go.mod` / `go.sum` 中。
- 生成失败时保留新工程供排查；不会清空已有项目。

## <span id="jobs-toc-heading-10" data-jobs-toc="v2">七、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

日志追加到系统临时目录中的 `【MacOS】GoProject.log`，运行自述会显示实际位置。日志文件使用当前用户私有权限，非终端和日志均为纯文本。

## <span id="jobs-toc-heading-11" data-jobs-toc="v2">八、常见问题 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">8.1、提示命令不存在 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

根据终端错误确认缺少的工具，先完成安装并保证命令已经加入 `PATH`。

### <span id="jobs-toc-heading-13" data-jobs-toc="v2">8.2、提示权限不足 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

检查目标文件权限和目录归属。只有确认命令及目标路径安全后，才按提示使用管理员权限。

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">8.3、双击后没有继续执行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

查看终端是否正在等待阅读确认或业务输入；不确定时按 `Ctrl+C` 退出后重新检查脚本。

## <span id="jobs-toc-heading-15" data-jobs-toc="v2">九、未执行声明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

静态语法及隔离夹具验证用于检查输入、失败和文件保护分支，不代表已在当前机器执行真实安装、服务启动或系统文件写入。

跳过依赖下载后得到可编辑骨架；首次运行前在生成目录执行 `go mod tidy`。module 路径应按实际仓库规划填写。参数约定参考 [Go module 官方教程](https://go.dev/doc/tutorial/create-module)。

[**Homebrew**](https://brew.sh/) 安装路径由用户选择：已有可运行安装时复用；确实需要安装时先强提示，只有精确输入大写 `YES` 才选择系统标准目录，其它输入或直接回车选择当前用户的 `.local/homebrew`。`YES` 只表示选择路径，权限与密码由官方安装器实际处理；有管理员权限也可以选用户目录。选定路径失败立即停止，不自动切换；`Ctrl+C` / 输入结束取消整个任务。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

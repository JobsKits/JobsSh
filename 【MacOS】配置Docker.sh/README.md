# `【MacOS】配置Docker.sh`

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

`【MacOS】配置Docker.sh` 分层检查 [**Docker Desktop**](https://docs.docker.com/desktop/setup/install/mac-install/) 应用、Docker CLI 和当前 context 的引擎连接，并按选择安装或升级。主脚本可独立运行，内置自述不依赖本 `README.md`，运行前先阅读影响范围。

| 关注点 | 真实行为 |
| --- | --- |
| CLI 发现 | 依次复用 PATH、用户 `.docker/bin`、实际 Docker.app 内 CLI；应用目录可用 `JOBS_DOCKER_APPDIR` 指定。 |
| Desktop 安装 | 使用当前 `docker-desktop` Cask；默认用户 Applications，用户目录禁用 sudo 和全局二进制链接。 |
| 就绪判断 | CLI 版本通过不等于引擎就绪；`docker info` 按当前 context 单独验证，有 15 秒默认截止时间。 |

下面是来源日志格式示例；最终下载地址由包管理器解析后输出，不把元数据地址当成实际安装包：

```text
━━━━━━━━━━ 来源｜安装/更新 ━━━━━━━━━━
📦 对象：Docker-Desktop
📥 来源地址：当前生效的软件源（URL 凭据和查询参数脱敏）
📂 目标位置：当前环境解析出的实际安装位置
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 需要检查 Docker 命令与引擎状态，或在系统、用户应用目录中管理 Desktop。
- 希望通过可重复运行的 Shell 脚本减少手工命令遗漏。
- 需要结合终端日志定位环境、路径或第三方工具问题。

脚本统一由 macOS 预置的 `/bin/zsh` 执行。双击或直接执行脚本即可；显式指定解释器时使用 `zsh`，不要使用 `bash` 或 `sh`。运行后先显示内置自述，确认后才进入业务；无法读取确认输入时会退出。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录结构 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```text
【MacOS】配置Docker.sh/
├── 【MacOS】配置Docker.sh
└── README.md
```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

执行链是 `Desktop / Docker CLI → Homebrew → curl / Git / bash`，仅选择安装或升级 Desktop 时才检查 Homebrew。健康的其它 Docker CLI / 引擎可直接复用；非 Homebrew 管理的已有 Desktop 需要使用应用内升级，脚本不覆盖。

当前脚本内置 Homebrew 自检，不依赖外置支持库。健康安装直接复用，不自动 `brew update` / 全局升级。缺失或损坏时先选路径：精确 `YES` 选系统标准目录，其它输入（含回车）选当前用户 `.local/homebrew`；选完后仍需普通安装确认，回车跳过并停止依赖该管理器的分支。用户目录克隆官方稳定版本并禁用 sudo；不保证非标准前缀和全部旧系统可用。失败不切换路径，安装后复检；是否保存 shellenv 另需 `YES`。

- 确认当前系统为 macOS，目标目录和当前用户正确。
- 打开主脚本检查业务命令，保留已有项目和配置备份。
- 安装、更新、升级直接回车跳过；输入任意字符后回车执行。
- 持久配置、系统目录和旧版清理必须精确输入 `YES`；EOF 立即停止。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">4.1、双击运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在 Finder 中打开当前目录并双击 `【MacOS】配置Docker.sh`。阅读终端自述后按回车继续，按 `Ctrl+C` 取消。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">4.2、终端运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```shell
zsh "./【MacOS】配置Docker.sh"
```

## <span id="jobs-toc-heading-8" data-jobs-toc="v2">五、操作流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、展示内置自述并确认，检查现有应用和 CLI。

2、安装/升级回车跳过；选择执行后，才检查 Homebrew 并解析当前官方 `docker-desktop` Cask。

3、用户目录使用 `--no-binaries` 与 `HOMEBREW_NO_SUDO=1`；目录在主目录之外时额外输入 `YES`。

4、安装后复检实际应用内 CLI；单独检查当前 context 的引擎。

5、引擎未就绪时可选择打开 Desktop 并复检；许可由用户在应用内确认，仍失败则返回非零。

## <span id="jobs-toc-heading-9" data-jobs-toc="v2">六、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

升级 Desktop 可能影响运行中的容器，应先保存工作。脚本不自动接受许可、不切换 context、不修改代理和镜像源。`JOBS_DOCKER_APPDIR` 应是应用父目录的绝对路径；`JOBS_DOCKER_CHECK_SECONDS` 只能是 1 至 60 的整数。远端 context 检查失败不能证明本机 Desktop 已损坏。

读取确认前不会创建日志或进行业务写入。配置备份保留在原配置旁，日志记录实际恢复位置；不会提交或推送仓库。

## <span id="jobs-toc-heading-10" data-jobs-toc="v2">七、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

确认后日志写入系统临时目录中的 `【MacOS】配置Docker.log`，启动时显示实际位置。文件为当前用户所有并限制为 `600`；日志包含脚本进度和外部命令输出，剥离 ANSI，URL 凭据与查询参数脱敏。安装前先显示对象、软件源和目标；包管理器尚未解析地址时明确标注。

## <span id="jobs-toc-heading-11" data-jobs-toc="v2">八、常见问题 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">8.1、提示命令不存在 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

CLI 可用而引擎检查失败时，先检查当前 context、Docker Desktop 首次设置和实际引擎。脚本会按失败状态退出，不把 CLI 安装成功写成引擎已经就绪。

### <span id="jobs-toc-heading-13" data-jobs-toc="v2">8.2、提示权限不足 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

检查目标文件权限和目录归属。用户配置与包操作失败时停止，不通过递归改权限或自动 sudo 绕过。配置是符号链接或存在受控块边界异常时保留原件并报错。

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">8.3、双击后没有继续执行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

查看终端是否正在等待阅读确认或业务输入；不确定时按 `Ctrl+C` 退出后重新检查脚本。

## <span id="jobs-toc-heading-15" data-jobs-toc="v2">九、未执行声明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

已做 `zsh -n` 静态检查和隔离假命令分支验证；未执行真实安装、升级、sudo 或服务启动。官方命令和配置依据：[Docker 官方安装说明](https://docs.docker.com/desktop/setup/install/mac-install/)、[当前 Cask 名称](https://formulae.brew.sh/cask/docker-desktop)。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

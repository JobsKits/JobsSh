# `【MacOS】升级Ruby环境.sh`

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

`【MacOS】升级Ruby环境.sh` 识别 [**Ruby**](https://www.ruby-lang.org) 的实际管理来源，通过 [**Homebrew**](https://brew.sh/) 或 [**rbenv**](https://github.com/rbenv/rbenv) 管理用户 Ruby，保护 macOS 系统 Ruby。主脚本可独立运行，内置自述不依赖本 `README.md`，运行前先阅读影响范围。

| 关注点 | 真实行为 |
| --- | --- |
| 来源识别 | 读取 Ruby 实际运行时；rbenv shim / versions 与 Homebrew Cellar / opt 分别路由，未知管理器保持只读。 |
| 系统 Ruby | 不会运行 `sudo gem update --system`；可另选安装 Homebrew Ruby。 |
| rbenv | 只选择 ruby-build 当前列出的稳定版本；用户默认版本需独立 `YES` 并备份 version 文件。 |

下面是来源日志格式示例；最终下载地址由包管理器解析后输出，不把元数据地址当成实际安装包：

```text
━━━━━━━━━━ 来源｜安装/更新 ━━━━━━━━━━
📦 对象：ruby
📥 来源地址：当前生效的软件源（URL 凭据和查询参数脱敏）
📂 目标位置：当前环境解析出的实际安装位置
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 需要升级当前 Homebrew / rbenv Ruby，或为系统 Ruby 之外另装可维护的用户 Ruby。
- 希望通过可重复运行的 Shell 脚本减少手工命令遗漏。
- 需要结合终端日志定位环境、路径或第三方工具问题。

脚本统一由 macOS 预置的 `/bin/zsh` 执行。双击或直接执行脚本即可；显式指定解释器时使用 `zsh`，不要使用 `bash` 或 `sh`。运行后先显示内置自述，确认后才进入业务；无法读取确认输入时会退出。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录结构 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```text
【MacOS】升级Ruby环境.sh/
├── 【MacOS】升级Ruby环境.sh
└── README.md
```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

按当前路径恢复所需依赖：`Homebrew Ruby → Homebrew`，或 `rbenv Ruby → rbenv + ruby-build`。已有健康 rbenv / ruby-build 可以独立工作；只有 ruby-build 缺失且用户选择修复时才通过 Homebrew 补齐。不会因为可选管理器不存在就强制安装。

当前脚本内置 Homebrew 自检，不依赖外置支持库。健康安装直接复用，不自动 `brew update` / 全局升级。缺失或损坏时先选路径：精确 `YES` 选系统标准目录，其它输入（含回车）选当前用户 `.local/homebrew`；选完后仍需普通安装确认，回车跳过并停止依赖该管理器的分支。用户目录克隆官方稳定版本并禁用 sudo；不保证非标准前缀和全部旧系统可用。失败不切换路径，安装后复检；是否保存 shellenv 另需 `YES`。

- 确认当前系统为 macOS，目标目录和当前用户正确。
- 打开主脚本检查业务命令，保留已有项目和配置备份。
- 安装、更新、升级直接回车跳过；输入任意字符后回车执行。
- 持久配置、系统目录和旧版清理必须精确输入 `YES`；EOF 立即停止。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">4.1、双击运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在 Finder 中打开当前目录并双击 `【MacOS】升级Ruby环境.sh`。阅读终端自述后按回车继续，按 `Ctrl+C` 取消。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">4.2、终端运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```shell
zsh "./【MacOS】升级Ruby环境.sh"
```

## <span id="jobs-toc-heading-8" data-jobs-toc="v2">五、操作流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、展示内置自述并确认；检查 Ruby 入口、实际路径和 rbenv 根目录。

2、当前属于 rbenv 时进入其版本安装分支；缺少 ruby-build 才询问修复。

3、rbenv 显示可安装的稳定版本，复用健康已有版本或安装一次，再验证 Ruby / Gem；`YES` 才备份并改用户默认。

4、当前属于 Homebrew 时保留已识别的 Ruby 公式；确认安装、升级或修复并复检 Ruby / Gem。

5、仅系统 Ruby 或没有健康 Ruby 时，可选择另装 Homebrew Ruby；`YES` 才备份并保存 Shell PATH，未知来源保持只读。

## <span id="jobs-toc-heading-9" data-jobs-toc="v2">六、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

Ruby 或 Gem 版本变化可能影响原生扩展与项目依赖。rbenv 用户默认仅影响没有 `.ruby-version` / `RBENV_VERSION` 覆盖的环境；安装成功不等于所有项目已切换。旧 Ruby 和项目锁文件不会被清理，rbenv 编译或 Homebrew 安装失败会停止下游动作。

读取确认前不会创建日志或进行业务写入。配置备份保留在原配置旁，日志记录实际恢复位置；不会提交或推送仓库。

## <span id="jobs-toc-heading-10" data-jobs-toc="v2">七、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

确认后日志写入系统临时目录中的 `【MacOS】升级Ruby环境.log`，启动时显示实际位置。文件为当前用户所有并限制为 `600`；日志包含脚本进度和外部命令输出，剥离 ANSI，URL 凭据与查询参数脱敏。安装前先显示对象、软件源和目标；包管理器尚未解析地址时明确标注。

## <span id="jobs-toc-heading-11" data-jobs-toc="v2">八、常见问题 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">8.1、提示命令不存在 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

若提示未知管理来源，使用原管理器升级；不会把所有 `command -v ruby` 成功的情况都误认作系统 Ruby。rbenv 只使用 ruby-build 已知稳定版本；需要更近期版本时先自行更新其定义。

### <span id="jobs-toc-heading-13" data-jobs-toc="v2">8.2、提示权限不足 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

检查目标文件权限和目录归属。用户配置与包操作失败时停止，不通过递归改权限或自动 sudo 绕过。配置是符号链接或存在受控块边界异常时保留原件并报错。

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">8.3、双击后没有继续执行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

查看终端是否正在等待阅读确认或业务输入；不确定时按 `Ctrl+C` 退出后重新检查脚本。

## <span id="jobs-toc-heading-15" data-jobs-toc="v2">九、未执行声明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

已做 `zsh -n` 静态检查和隔离假命令分支验证；未执行真实安装、升级、sudo 或服务启动。官方命令和配置依据：[Ruby 官方安装说明](https://www.ruby-lang.org/en/documentation/installation/)、[rbenv 安装和版本选择](https://github.com/rbenv/rbenv#installing-ruby-versions)。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

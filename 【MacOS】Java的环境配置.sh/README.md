# `【MacOS】Java的环境配置.sh`

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

`【MacOS】Java的环境配置.sh` 检查现有 [**Java**](https://www.java.com/) JDK，按 [**Homebrew**](https://brew.sh/) 当前可用的 [**OpenJDK**](https://openjdk.org) 公式安装或升级，并按确认配置 `JAVA_HOME`。主脚本可独立运行，内置自述不依赖本 `README.md`，运行前先阅读影响范围。

| 关注点 | 真实行为 |
| --- | --- |
| 已有 JDK | 同时验证 `java -version` 与 `javac -version`；跳过管理时不引入 Homebrew。 |
| 版本选择 | 展示当前 `openjdk` 公式；回车选择 `8`，`latest` 选择无版本后缀公式；以当前公式可用性为准。 |
| 安装与配置 | 安装、升级或修复各自确认；用户 Shell 配置独立输入 `YES`，先备份再替换 `Jobs Java` 块。 |

下面是来源日志格式示例；最终下载地址由包管理器解析后输出，不把元数据地址当成实际安装包：

```text
━━━━━━━━━━ 来源｜安装/更新 ━━━━━━━━━━
📦 对象：openjdk@8
📥 来源地址：当前生效的软件源（URL 凭据和查询参数脱敏）
📂 目标位置：当前环境解析出的实际安装位置
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 需要检查现有 JDK、选择不同主版本，或为当前用户配置 Java 编译运行环境。
- 希望通过可重复运行的 Shell 脚本减少手工命令遗漏。
- 需要结合终端日志定位环境、路径或第三方工具问题。

脚本统一由 macOS 预置的 `/bin/zsh` 执行。双击或直接执行脚本即可；显式指定解释器时使用 `zsh`，不要使用 `bash` 或 `sh`。运行后先显示内置自述，确认后才进入业务；无法读取确认输入时会退出。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录结构 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```text
【MacOS】Java的环境配置.sh/
├── 【MacOS】Java的环境配置.sh
└── README.md
```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

执行链是 `JDK → Homebrew → curl / Git / bash`，仅在用户选择 Homebrew 管理分支时检查上游。系统 Java 占位程序和缺少编译器的 JRE 不计作健康 JDK。JDK 的路径来自 `brew --prefix <公式>`，兼容系统及用户 Homebrew 前缀。

当前脚本内置 Homebrew 自检，不依赖外置支持库。健康安装直接复用，不自动 `brew update` / 全局升级。缺失或损坏时先选路径：精确 `YES` 选系统标准目录，其它输入（含回车）选当前用户 `.local/homebrew`；选完后仍需普通安装确认，回车跳过并停止依赖该管理器的分支。用户目录克隆官方稳定版本并禁用 sudo；不保证非标准前缀和全部旧系统可用。失败不切换路径，安装后复检；是否保存 shellenv 另需 `YES`。

- 确认当前系统为 macOS，目标目录和当前用户正确。
- 打开主脚本检查业务命令，保留已有项目和配置备份。
- 安装、更新、升级直接回车跳过；输入任意字符后回车执行。
- 持久配置、系统目录和旧版清理必须精确输入 `YES`；EOF 立即停止。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">4.1、双击运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在 Finder 中打开当前目录并双击 `【MacOS】Java的环境配置.sh`。阅读终端自述后按回车继续，按 `Ctrl+C` 取消。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">4.2、终端运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```shell
zsh "./【MacOS】Java的环境配置.sh"
```

## <span id="jobs-toc-heading-8" data-jobs-toc="v2">五、操作流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、展示内置自述，回车确认后初始化日志并检查已有 JDK。

2、普通确认后进入 Homebrew 管理；显示当前可用公式并选择 JDK 主版本。

3、按健康情况询问安装、升级或重新安装；失败后停止，成功后复检 Java 与编译器。

4、选择已有或新装 JDK 后，输入 `YES` 才备份并写当前 Shell 的 `JAVA_HOME` / `PATH` 受控块。

5、显示实际 JDK Home 与日志；不会挂载下载页、执行系统安装器或创建系统 JDK 链接。

## <span id="jobs-toc-heading-9" data-jobs-toc="v2">六、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

JDK 升级可能影响依赖特定主版本的项目；版本选择以当前 Homebrew 元数据为准。`openjdk@8` 不保证在所有 CPU / macOS 上可安装，失败后不会改选其它版本。Shell 配置可能改变后续终端的默认 Java；备份与恢复位置在日志中给出。

读取确认前不会创建日志或进行业务写入。配置备份保留在原配置旁，日志记录实际恢复位置；不会提交或推送仓库。

## <span id="jobs-toc-heading-10" data-jobs-toc="v2">七、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

确认后日志写入系统临时目录中的 `【MacOS】Java的环境配置.log`，启动时显示实际位置。文件为当前用户所有并限制为 `600`；日志包含脚本进度和外部命令输出，剥离 ANSI，URL 凭据与查询参数脱敏。安装前先显示对象、软件源和目标；包管理器尚未解析地址时明确标注。

## <span id="jobs-toc-heading-11" data-jobs-toc="v2">八、常见问题 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">8.1、提示命令不存在 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

若公式不存在或目标架构不受支持，根据显示的公式清单重新选择；脚本不会把 HTML 下载页当成 JDK 安装包。只有独立编译器也可运行才计为完整 JDK。

### <span id="jobs-toc-heading-13" data-jobs-toc="v2">8.2、提示权限不足 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

检查目标文件权限和目录归属。用户配置与包操作失败时停止，不通过递归改权限或自动 sudo 绕过。配置是符号链接或存在受控块边界异常时保留原件并报错。

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">8.3、双击后没有继续执行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

查看终端是否正在等待阅读确认或业务输入；不确定时按 `Ctrl+C` 退出后重新检查脚本。

## <span id="jobs-toc-heading-15" data-jobs-toc="v2">九、未执行声明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

已做 `zsh -n` 静态检查和隔离假命令分支验证；未执行真实安装、升级、sudo 或服务启动。官方命令和配置依据：[OpenJDK 公式说明](https://formulae.brew.sh/formula/openjdk)。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

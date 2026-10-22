# `【MacOS】关于Gem.sh`

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

`【MacOS】关于Gem.sh` 检查 [**Ruby**](https://www.ruby-lang.org) / [**Gem**](https://rubygems.org/) 环境，查看软件源，并按确认维护用户源、RubyGems 本体、已安装 Gem 和旧版本。主脚本可独立运行，内置自述不依赖本 `README.md`，运行前先阅读影响范围。

| 关注点 | 真实行为 |
| --- | --- |
| 系统保护 | macOS 系统 Ruby / Gem 仅检查；不执行 `sudo`，不升级系统 RubyGems。 |
| 软件源 | 回车保留、1 官方、2 Ruby China；输入 `YES` 后先备份 `.gemrc`，通过 RubyGems API 保留其它键。 |
| 更新与清理 | RubyGems 与全部 Gem 更新分别回车跳过；删除旧 Gem 独立输入 `YES`。 |

下面是来源日志格式示例；最终下载地址由包管理器解析后输出，不把元数据地址当成实际安装包：

```text
━━━━━━━━━━ 来源｜安装/更新 ━━━━━━━━━━
📦 对象：RubyGems
📥 来源地址：当前生效的软件源（URL 凭据和查询参数脱敏）
📂 目标位置：当前环境解析出的实际安装位置
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 需要检查 Gem 运行环境、选择官方或 Ruby China 软件源，或维护用户 Ruby 中的 Gem。
- 希望通过可重复运行的 Shell 脚本减少手工命令遗漏。
- 需要结合终端日志定位环境、路径或第三方工具问题。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录结构 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```text
【MacOS】关于Gem.sh/
├── 【MacOS】关于Gem.sh
└── README.md
```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

仅依赖已有健康 Ruby / Gem，不为了查看或维护 Gem 引入 Homebrew。读取 Gem 实际 Ruby 执行路径和 Gem Home；系统目录或不可写环境停止更新分支，用户配置软件源仍可单独选择。需要新 Ruby 时使用同仓 Ruby 升级入口。

- 确认当前系统为 macOS，目标目录和当前用户正确。
- 打开主脚本检查业务命令，保留已有项目和配置备份。
- 安装、更新、升级直接回车跳过；输入任意字符后回车执行。
- 持久配置、系统目录和旧版清理必须精确输入 `YES`；EOF 立即停止。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">4.1、双击运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在 Finder 中打开当前目录并双击 `【MacOS】关于Gem.sh`。阅读终端自述后按回车继续，按 `Ctrl+C` 取消。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">4.2、终端运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```shell
zsh "./【MacOS】关于Gem.sh"
```

## <span id="jobs-toc-heading-8" data-jobs-toc="v2">五、操作流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、展示内置自述并确认；检查 Ruby、Gem 和实际 Gem Home，显示脱敏软件源。

2、回车保留源，或选择官方 / Ruby China；输入 `YES` 后备份用户 `.gemrc`，写入并复检。

3、识别系统 Ruby / Gem 或不可写 Gem Home，命中时跳过所有包更新与清理。

4、用户环境分别询问 RubyGems 本体和当前环境全部 Gem 更新；任一步失败立即退出。

5、输入 `YES` 才清理旧 Gem，显示日志与配置恢复依据。

## <span id="jobs-toc-heading-9" data-jobs-toc="v2">六、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

切换软件源会改变后续 Gem 下载来源；Ruby China 属于第三方镜像，选择前自行确认可用性。更新全部 Gem 可能影响项目兼容，清理旧版可能使仍依赖旧版本的项目失败。脚本只操作当前环境，不修改项目锁文件。

读取确认前不会创建日志或进行业务写入。配置备份保留在原配置旁，日志记录实际恢复位置；不会提交或推送仓库。

## <span id="jobs-toc-heading-10" data-jobs-toc="v2">七、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

确认后日志写入系统临时目录中的 `【MacOS】关于Gem.log`，启动时显示实际位置。文件为当前用户所有并限制为 `600`；日志包含脚本进度和外部命令输出，剥离 ANSI，URL 凭据与查询参数脱敏。安装前先显示对象、软件源和目标；包管理器尚未解析地址时明确标注。

## <span id="jobs-toc-heading-11" data-jobs-toc="v2">八、常见问题 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">8.1、提示命令不存在 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

系统 Ruby 的升级分支会明确跳过；先准备用户 Ruby 并确认 PATH，再维护该环境。Gem Home 不可写时停止包修改，不通过 sudo 绕过；配置恢复使用日志中的 `.gemrc` 备份。

### <span id="jobs-toc-heading-13" data-jobs-toc="v2">8.2、提示权限不足 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

检查目标文件权限和目录归属。用户配置与包操作失败时停止，不通过递归改权限或自动 sudo 绕过。配置是符号链接或存在受控块边界异常时保留原件并报错。

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">8.3、双击后没有继续执行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

查看终端是否正在等待阅读确认或业务输入；不确定时按 `Ctrl+C` 退出后重新检查脚本。

## <span id="jobs-toc-heading-15" data-jobs-toc="v2">九、未执行声明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

已做 `zsh -n` 静态检查和隔离假命令分支验证；未执行真实安装、升级、sudo 或服务启动。官方命令和配置依据：[RubyGems 命令参考](https://guides.rubygems.org/command-reference/)、[Ruby China Gem 镜像](https://gems.ruby-china.com/)。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

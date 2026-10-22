# `【MacOS】JobsSql.sh`

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

`【MacOS】JobsSql.sh` 用于安装或升级 [**MySQL**](https://dev.mysql.com/doc/)，按需启动服务和进入 root 交互客户端。已有数据库和认证配置保持启用；不会修改 Cellar 模板或写入 `skip-grant-tables`。主脚本可独立运行；本 `README.md` 用于运行前阅读，运行时自述直接写在脚本中。

来源日志会在真实下载/升级前显示对象、当前软件源和目标。包管理器的最终下载地址由 `brew` 自己解析，不预先猜测；日志显示副本会脱敏，并列出当前 API、Bottle、Artifact 域名与 `brew config` 报告的来源覆盖项。未覆盖来源时示例：

```text
━━━━━━━━━━ 来源 ━━━━━━━━━━
对象：mysql 安装
来源地址：Homebrew 当前生效软件源；最终包下载地址待 brew 解析
目标位置：当前 brew --prefix 返回的真实前缀
━━━━━━━━━━━━━━━━━━━━━━━━━━
Formula API：https://formulae.brew.sh/api
Bottle 域名：https://ghcr.io/v2/homebrew/core
```

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 首次准备本机 MySQL，或升级已经安装的 `mysql` / `mysql@版本` 公式。
- 希望通过可重复运行的 Shell 脚本减少手工命令遗漏。
- 需要结合终端日志定位环境、路径或第三方工具问题。

脚本统一由 macOS 预置的 `/bin/zsh` 执行。双击或直接执行脚本即可；显式指定解释器时使用 `zsh`，不要使用 `bash` 或 `sh`。运行后先显示内置自述，确认后才进入业务；无法读取确认输入时会退出。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录结构 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```text
【MacOS】JobsSql.sh/
├── 【MacOS】JobsSql.sh
└── README.md
```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

当前脚本内包含 [**Homebrew**](https://brew.sh/) 自检、缺失安装路径选择和当前进程激活，不依赖外置模块。先检查候选命令、真实前缀、`shellenv` 和命令层健康；只有普通安装确认通过才安装。精确 `YES` 选择系统前缀，其它输入选择用户前缀；EOF 直接停止，失败不切换路径。

- 确认当前系统为 MacOS，并已安装脚本实际调用的工具。
- 确认脚本路径、工程目录、输入文件和当前 Git 工作区正确。
- 打开主脚本检查其中的业务命令，不理解的操作不要直接执行。
- 涉及安装、更新或升级时，以脚本终端提示为准；直接回车应表示跳过。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">4.1、双击运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在 Finder 中打开当前目录并双击 `【MacOS】JobsSql.sh`。阅读终端自述后按回车继续，按 `Ctrl+C` 取消。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">4.2、终端运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```shell
cd "脚本所在目录/【MacOS】JobsSql.sh"
./【MacOS】JobsSql.sh
```

## <span id="jobs-toc-heading-8" data-jobs-toc="v2">五、操作流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、先显示固定内置自述，按回车确认；无终端、取消或输入结束均停止。

2、在脚本内部发现并验证 Homebrew。缺失时，普通安装确认直接回车跳过；输入任意字符后才进入安装位置选择：精确 `YES` 选系统目录，其它输入选用户目录，安装失败停止。

3、询问是否更新 Homebrew 自身和索引；已有 MySQL 询问升级，缺失时询问安装。上述普通动作均回车跳过、任意字符执行。

4、显示所选公式信息。多版本时输入完整公式名；可按需启动/重启服务，再进入由客户端读取密码的 root 交互登录。

5、输出执行结果和日志路径；不会因为升级失败继续启动服务，也不会声称修改了 root 密码。

## <span id="jobs-toc-heading-9" data-jobs-toc="v2">六、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 跨版本升级前自行完成可恢复的数据库备份，并核对官方升级兼容性。
- 用户目录 Homebrew 属于非标准前缀，部分软件可能需要源码构建；失败不会自动改装系统目录。
- 启动服务前拒绝检测到的 `skip-grant-tables`；已有不安全配置需要人工修复后再运行。
- 不自动卸载、删除数据库、执行全局 `brew upgrade` 或覆盖系统 `my.cnf`。

## <span id="jobs-toc-heading-10" data-jobs-toc="v2">七、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

确认自述后创建系统临时目录中的 `【MacOS】JobsSql.log`，并同步显示在终端。外部命令输出会过滤 ANSI 和常见密码、Token、URL 凭据及查询参数；不记录交互登录密码。日志文件为当前用户私有权限，后一次运行会覆盖同名日志。

## <span id="jobs-toc-heading-11" data-jobs-toc="v2">八、常见问题 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">8.1、提示命令不存在 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

根据终端错误确认缺少的工具，先完成安装并保证命令已经加入 `PATH`。

### <span id="jobs-toc-heading-13" data-jobs-toc="v2">8.2、提示权限不足 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

检查目标文件权限、目录归属和终端显示的实际前缀。配置、重置和卸载入口不通过 `sudo` 绕过目录保护；修复归属后重新运行。

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">8.3、双击后没有继续执行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

查看终端是否正在等待阅读确认或业务输入；不确定时按 `Ctrl+C` 退出后重新检查脚本。

## <span id="jobs-toc-heading-15" data-jobs-toc="v2">九、未执行声明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

已进行 `zsh -n` 静态检查和隔离假命令分支验证；未真实安装、升级、启动/停止 MySQL、重建或删除数据库，也未执行 `sudo`。本地检查不能替代实际数据库备份与目标机器验收。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

# `【MacOS】删除brew-MySql数据库并重置密码为空.sh`

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

`【MacOS】删除brew-MySql数据库并重置密码为空.sh` 用于为本机开发环境重建 [**MySQL**](https://dev.mysql.com/doc/) 数据目录和账户，使用 `--initialize-insecure` 创建空密码 `root@localhost`。旧数据整体移为同级备份，只有真实 socket 登录并核对数据目录成功后才报告完成。主脚本可独立运行；本 `README.md` 用于运行前阅读，运行时自述直接写在脚本中。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 明确需要重建全部本地数据库和账户、并暂时使用 root 空密码的开发环境。
- 希望通过可重复运行的 Shell 脚本减少手工命令遗漏。
- 需要结合终端日志定位环境、路径或第三方工具问题。

脚本统一由 macOS 预置的 `/bin/zsh` 执行。双击或直接执行脚本即可；显式指定解释器时使用 `zsh`，不要使用 `bash` 或 `sh`。运行后先显示内置自述，确认后才进入业务；无法读取确认输入时会退出。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录结构 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```text
【MacOS】删除brew-MySql数据库并重置密码为空.sh/
├── 【MacOS】删除brew-MySql数据库并重置密码为空.sh
└── README.md
```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

当前脚本内包含 [**Homebrew**](https://brew.sh/) 健康发现与当前进程激活，不依赖外置模块。仅复用已有健康安装及 MySQL 程序；缺失或损坏时停止，首次安装请使用 `../【MacOS】JobsSql.sh/【MacOS】JobsSql.sh`。

- 确认当前系统为 MacOS，并已安装脚本实际调用的工具。
- 确认脚本路径、工程目录、输入文件和当前 Git 工作区正确。
- 打开主脚本检查其中的业务命令，不理解的操作不要直接执行。
- 涉及安装、更新或升级时，以脚本终端提示为准；直接回车应表示跳过。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">4.1、双击运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在 Finder 中打开当前目录并双击 `【MacOS】删除brew-MySql数据库并重置密码为空.sh`。阅读终端自述后按回车继续，按 `Ctrl+C` 取消。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">4.2、终端运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```shell
cd "脚本所在目录/【MacOS】删除brew-MySql数据库并重置密码为空.sh"
./【MacOS】删除brew-MySql数据库并重置密码为空.sh
```

## <span id="jobs-toc-heading-8" data-jobs-toc="v2">五、操作流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、显示固定内置自述并等待回车；随后检查已有健康 Homebrew 与 MySQL，多版本时选择完整公式名。

2、读取 MySQL 实际配置，要求数据目录为当前 Homebrew 默认 `var/mysql`、认证正常启用、经典协议及启用的 X Protocol 仅监听回环地址。

3、展示影响范围；只有精确输入 `YES` 才重建全部数据库和账户，其它输入取消。

4、记录原服务状态并停止服务；任何 mysqld / mysqld_safe 仍运行或进程检查失败时停止，不移动数据。

5、将旧目录完整移至 `mysql.jobs-backup-日期时间-进程号`，再用同一 MySQL 程序的 `--no-defaults --initialize-insecure` 初始化新目录，不修改认证配置。

6、启动服务，并用忽略用户密码配置的本地 socket 实际连接验证 `root@localhost` 空密码和新数据目录。失败或中断时保留失败的新目录并尝试恢复旧目录、原服务状态。

7、成功后显示日志和备份位置，提醒及时设置 root 密码；历史备份不会自动删除。初始化行为依据 [MySQL 官方数据目录初始化说明](https://dev.mysql.com/doc/refman/8.4/en/data-directory-initialization.html)。

## <span id="jobs-toc-heading-9" data-jobs-toc="v2">六、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 重置后全部原数据库、账户和密码从新实例中消失；旧目录备份需手工保留和核对，恢复时必须先停止服务。
- 仅支持默认数据目录和回环监听；自定义目录、符号链接、远程监听及启用 `skip-grant-tables` 的配置均会被拒绝。
- 不会通过禁用认证假装密码已清空，也不会自动卸载或重新安装 MySQL。已有程序不可用时停止并提示修复。
- 空密码只适用于临时本机开发；请尽快在交互客户端设置密码。

## <span id="jobs-toc-heading-10" data-jobs-toc="v2">七、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

确认自述后创建系统临时目录中的 `【MacOS】删除brew-MySql数据库并重置密码为空.log`，并同步显示在终端。外部命令输出会过滤 ANSI 和常见密码、Token、URL 凭据及查询参数；不记录交互登录密码。日志文件为当前用户私有权限，后一次运行会覆盖同名日志。

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

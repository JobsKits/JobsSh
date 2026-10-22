# `【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh`

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

`【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh` 用于编辑和验证 [**MySQL**](https://dev.mysql.com/doc/) 的 Homebrew 前缀下 `etc/my.cnf`。先编辑临时副本，精确 `YES` 确认后备份原配置并原子替换；失败时尝试恢复。主脚本可独立运行；本 `README.md` 用于运行前阅读，运行时自述直接写在脚本中。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 调整本机 MySQL 配置，保存后按需重启服务。
- 希望通过可重复运行的 Shell 脚本减少手工命令遗漏。
- 需要结合终端日志定位环境、路径或第三方工具问题。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录结构 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```text
【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh/
├── 【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh
└── README.md
```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

当前脚本内包含 [**Homebrew**](https://brew.sh/) 健康发现与当前进程激活，不依赖外置模块。仅复用已有健康安装；缺失或损坏时停止，不为了配置任务安装管理器。

- 确认当前系统为 MacOS，并已安装脚本实际调用的工具。
- 确认脚本路径、工程目录、输入文件和当前 Git 工作区正确。
- 打开主脚本检查其中的业务命令，不理解的操作不要直接执行。
- 涉及安装、更新或升级时，以脚本终端提示为准；直接回车应表示跳过。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">4.1、双击运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在 Finder 中打开当前目录并双击 `【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh`。阅读终端自述后按回车继续，按 `Ctrl+C` 取消。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">4.2、终端运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```shell
cd "脚本所在目录/【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh"
./【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh
```

## <span id="jobs-toc-heading-8" data-jobs-toc="v2">五、操作流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、显示固定内置自述并等待回车确认，再初始化日志与临时目录。

2、检查健康 Homebrew 和所选 MySQL，动态解析程序及 `etc/my.cnf` 路径；多版本时输入完整公式名。

3、复制原配置到临时副本；原文件不存在时建立带本机监听的候选配置。优先使用 `code --wait` 编辑，没有该命令时使用系统 `vi`。

4、编辑器退出后拒绝 `skip-grant-tables`，执行 `mysqld --validate-config`。编辑期间原文件变化会停止，保留并发修改。

5、只有精确输入 `YES` 才保存；已有文件在同目录生成 `my.cnf.jobs-backup.随机后缀`，然后原子替换并验证整体有效配置与认证状态。

6、按需重启服务：回车跳过、任意字符执行。重启或校验失败会尝试恢复原配置及原服务状态；配置发生并发变化时保留现状并报告备份位置。

## <span id="jobs-toc-heading-9" data-jobs-toc="v2">六、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 只处理 Homebrew 前缀下的普通 `etc/my.cnf`，拒绝符号链接和不可写目录；不使用 `sudo` 覆盖 `/etc/my.cnf`。
- 可在候选配置中按需要启用 GTID；新文件只提供注释示例，不反复追加旧式参数。
- 应用配置会改变服务行为，必须精确输入 `YES`；服务重启仍需单独确认。
- 恢复只覆盖本次仍保持预期内容的文件；发生并发修改或服务恢复失败时，日志会明确报告并保留备份。

## <span id="jobs-toc-heading-10" data-jobs-toc="v2">七、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

确认自述后创建系统临时目录中的 `【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.log`，并同步显示在终端。外部命令输出会过滤 ANSI 和常见密码、Token、URL 凭据及查询参数；不记录交互登录密码。日志文件为当前用户私有权限，后一次运行会覆盖同名日志。

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

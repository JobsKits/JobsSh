# `【WindowsOS】Ruby环境升级.ps1`

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、运行与依赖](#jobs-toc-heading-2)
- [二、验证范围](#jobs-toc-heading-3)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> **目的：** Ruby环境安装升级。

- winget列出RubyInstaller当前目录，由用户复制精确RubyInstallerTeam版本包ID后YES执行安装/升级；不猜测新版本、不覆盖未知Ruby管理器，完成后重开终端验证ruby/gem。
- [PowerShell入口](<./【WindowsOS】Ruby环境升级.ps1>)；只读检查：`& .\【WindowsOS】Ruby环境升级.ps1 -Check`。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、运行与依赖 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 最低声明环境：[**Windows**](https://www.microsoft.com/windows) 10 x64、[**Windows PowerShell**](https://learn.microsoft.com/powershell/) 5.1；具体工具与服务依赖见[平台说明](../README.md)。最低系统 build 与 x64 实机仍待验。
- 双击本包 `【WindowsOS】Ruby环境升级.cmd`，或在 PowerShell 使用 `& .\【WindowsOS】Ruby环境升级.ps1`；带 `-Check` 只读检查，不安装、不启动业务、不写业务文件。
- 保持本包与上级 `JobsTools.ps1` 的相对布局；不依赖启动工作目录。入口先显示内置用途与影响，确认后再初始化日志，写操作按既有危险门禁确认。Ctrl+C 或输入结束取消。
- 本次日志在系统临时目录生成，运行中显示真实路径；原生工具失败返回非零。`.cmd` 仅转交本次进程，不持久修改执行策略。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、验证范围 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

本轮核对包内路径与 PowerShell 语法；Windows 5.1、CMD 原生参数、真实工具安装及服务行为须按[平台说明](../README.md)分别验收，不能由语法检查推定通过。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

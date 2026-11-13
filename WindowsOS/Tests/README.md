# <span id="前言">Windows 环境与服务隔离测试</span>

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [一、运行方式](#jobs-toc-heading-1)
- [二、隔离边界](#jobs-toc-heading-2)

</details>
<!-- jobs-toc:end -->

---

## <span id="jobs-toc-heading-1" data-jobs-toc="v2">一、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在此目录使用 [**PowerShell**](https://learn.microsoft.com/powershell/) 运行：

```powershell
& ./Regression.ps1
```

`-SkipEntrypoints` 只运行模块夹具。macOS 完整检查为 39 项断言，Windows 为 37 项，覆盖精确 `YES`、BOM、祖先链接拒绝、路径内 `%TEMP%` 字面保留、显式环境变量根与缺变量停止、重建取消、旧容器改名失败、创建失败时恢复原名称与运行状态、保留数据卷，以及全部 15 个入口的 `-Check`。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">二、隔离边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

[**Docker**](https://docs.docker.com/) 交互由假函数记录，用户配置与安装器不调用。只在唯一临时目录读写；macOS 上执行的链接夹具不替代 Windows 目录联接实机验收。2026-10-26 在 Windows 11 ARM64 / Windows PowerShell 5.1.26100.9711 原生通过 33 项；根 CMD 回归另验证 GoProject 入口在无继承进程执行策略时的真实 `-Check`。WSL2、Docker 和真实服务业务仍需单独验收。



<!-- JOBS_TERMINAL_STYLE_V1:BEGIN -->

> Windows 终端配色保护：支持完整颜色查询的交互控制台会先保存当前会话默认前景、背景与16色色表，再临时使用黑底白字和统一强调色；正常结束、业务失败及可捕获中断后恢复。用户运行中自行改动的颜色保留并提示，不修改用户主题、共享 Profile、注册表或全局策略。快照不包含进入前任意叠加的临时文字样式。非控制台、重定向、`NO_COLOR`、Sourcetree 及无法可靠保存／恢复颜色的环境保持原状态或降级为纯文本。

> 强制结束进程或终端崩溃无法保证自动恢复。恢复失败时保留并提示本轮 `%TEMP%\JobsTerminalStyle-<PID>-*.ps1` 恢复脚本，需在原控制台核对后运行；不要通过重置用户配置恢复。`-ExecutionPolicy Bypass` 如被入口使用，仅作用于本次子进程，不持久修改策略。

> 验证范围：已完成 PowerShell 语法、参数／退出与隔离生命周期核验；Windows 原生控制台的显示、按键与 `Ctrl+C` 实机验证尚未完成。

<!-- JOBS_TERMINAL_STYLE_V1:END -->

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

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

`-SkipEntrypoints` 只运行模块夹具。macOS 完整检查为 35 项断言，Windows 为 33 项，覆盖精确 `YES`、BOM、祖先链接拒绝、重建取消、旧容器改名失败、创建失败时恢复原名称与运行状态、保留数据卷，以及全部 15 个入口的 `-Check`。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">二、隔离边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

[**Docker**](https://docs.docker.com/) 交互由假函数记录，用户配置与安装器不调用。只在唯一临时目录读写；macOS 上执行的链接夹具不替代 Windows 目录联接实机验收。2026-10-26 在 Windows 11 ARM64 / Windows PowerShell 5.1.26100.9711 原生通过 33 项；根 CMD 回归另验证 GoProject 入口在无继承进程执行策略时的真实 `-Check`。WSL2、Docker 和真实服务业务仍需单独验收。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

# `JobsSh.sh` WindowsOS 脚本

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、运行方式](#jobs-toc-heading-2)
- [二、入口与流程](#jobs-toc-heading-3)
  - [【WindowsOS】MySQL管理.cmd](#jobs-toc-heading-4)
  - [【WindowsOS】MySQL配置.cmd](#jobs-toc-heading-5)
  - [【WindowsOS】MySQL重建空密码.cmd](#jobs-toc-heading-6)
  - [【WindowsOS】MySQL卸载.cmd](#jobs-toc-heading-7)
  - [【WindowsOS】GoProject.cmd](#jobs-toc-heading-8)
  - [【WindowsOS】HEIC2Jpg.cmd](#jobs-toc-heading-9)
  - [【WindowsOS】Java环境配置.cmd](#jobs-toc-heading-10)
  - [【WindowsOS】PHP与Apache.cmd](#jobs-toc-heading-11)
  - [【WindowsOS】Tomcat.cmd](#jobs-toc-heading-12)
  - [【WindowsOS】网页视频下载.cmd](#jobs-toc-heading-13)
  - [【WindowsOS】RubyGems.cmd](#jobs-toc-heading-14)
  - [【WindowsOS】Ruby环境升级.cmd](#jobs-toc-heading-15)
  - [【WindowsOS】受保护文件追加.cmd](#jobs-toc-heading-16)
  - [【WindowsOS】文件扩展名显示.cmd](#jobs-toc-heading-17)
  - [【WindowsOS】Docker配置.cmd](#jobs-toc-heading-18)
- [三、平台差异与验证](#jobs-toc-heading-19)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

本目录提供与原脚本功能对应的[**Windows**](https://www.microsoft.com/windows)入口，按当前平台的工具、权限和服务方式执行。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

[**Windows**](https://www.microsoft.com/windows) 10/11，[**Windows PowerShell**](https://learn.microsoft.com/powershell/) 5.1 或更新版本。双击对应 `.cmd`，或在 PowerShell 使用 `& .\【WindowsOS】脚本名.ps1`；入口全部先显示用途并等待回车，写操作再按提示精确输入 `YES`。可用 `-Check` 只读加载与查询本地依赖，不安装、启动或写业务文件。输入重定向/EOF直接停止；取消用Ctrl+C。`.ps1`以UTF-8 BOM保存，`.cmd`仅为双击转发，不持久修改ExecutionPolicy；被企业策略拦截时遵循本机已批准策略。

`JobsTools.ps1`只定义公共与业务函数；各脚本入口按自身路径加载，不能单独拷贝一个入口后遗漏模块。状态/备份分别保存在当前用户的本地应用数据目录 `JobsCommandOthers` 或 `JobsSh`；每次运行的状态日志保存于系统临时目录中的独立 `Jobs-*.log` 或 `JobsSh-*.log`，自述确认后显示真实位置。下载前显示来源与目标，URL凭据/查询参数脱敏。

递归文件工具默认排除 `.git`、`node_modules`、`Pods`、`.dart_tool`、`build`、`DerivedData`与链接。服务仅绑定回环地址；[**Docker**](https://docs.docker.com/)只操作专属标签容器，不卸载其它软件或清理其它数据。命令失败返回非零，备份保留供检查恢复。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、入口与流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-4" data-jobs-toc="v2">[【WindowsOS】MySQL管理.cmd](<./【WindowsOS】MySQL管理.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** MySQL安装与管理。

- 用[**Docker**](https://docs.docker.com/)官方[**MySQL**](https://www.mysql.com/) `mysql:8.4`替代[**Homebrew**](https://brew.sh/)服务，支持install / start / stop / status / login / logs。首次创建专属容器与独立持久数据卷，回环3306，正常安装要求至少8字符root密码；密码不记日志，但Docker环境变量仍由有权操作Docker的用户可见。ping健康与实际认证分开；login使用交互密码。
- [PowerShell入口](<./【WindowsOS】MySQL管理.ps1>)；只读检查：`& .\【WindowsOS】MySQL管理.ps1 -Check`。

### <span id="jobs-toc-heading-5" data-jobs-toc="v2">[【WindowsOS】MySQL配置.cmd](<./【WindowsOS】MySQL配置.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** MySQL配置。

- 选择已编辑my.cnf，使用同版官方镜像隔离 --validate-config；核对本工具容器与挂载，YES后备份、写入并按原运行状态重启。健康检查失败恢复原配置；不处理其它MySQL实例。
- [PowerShell入口](<./【WindowsOS】MySQL配置.ps1>)；只读检查：`& .\【WindowsOS】MySQL配置.ps1 -Check`。

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">[【WindowsOS】MySQL重建空密码.cmd](<./【WindowsOS】MySQL重建空密码.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** 保留旧数据并重建空密码。

- YES后停止并改名保留旧容器和旧卷，再创建全新数据卷/空密码MySQL，仅回环3306。实连验证root空密码；失败移除本次新容器、恢复旧名称及原运行状态，数据卷不删除；停止成功但改名失败也恢复原运行状态。仅供本机测试。
- [PowerShell入口](<./【WindowsOS】MySQL重建空密码.ps1>)；只读检查：`& .\【WindowsOS】MySQL重建空密码.ps1 -Check`。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">[【WindowsOS】MySQL卸载.cmd](<./【WindowsOS】MySQL卸载.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** 卸载MySQL容器。

- 核对本工具专属容器标签，YES后停止移除，默认保留全部数据卷。只有再次输入完整专属卷名并YES，才删除该单个卷；Docker发现卷被使用时拒绝删除。
- [PowerShell入口](<./【WindowsOS】MySQL卸载.ps1>)；只读检查：`& .\【WindowsOS】MySQL卸载.ps1 -Check`。

### <span id="jobs-toc-heading-8" data-jobs-toc="v2">[【WindowsOS】GoProject.cmd](<./【WindowsOS】GoProject.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** Gin工程生成。

- 可选install经[**winget**](https://learn.microsoft.com/windows/package-manager/winget/)安装/升级GoLang.Go；检查[**Go**](https://go.dev/) `go.exe`，输入父目录、工程名与module；拒绝覆盖，确认后创建main.go与go.mod，生成回环8080的/ping路由。另选YES才下载Gin依赖、go test，校验成功才可前台运行；Go缺失可用winget安装GoLang.Go。
- [PowerShell入口](<./【WindowsOS】GoProject.ps1>)；只读检查：`& .\【WindowsOS】GoProject.ps1 -Check`。

### <span id="jobs-toc-heading-9" data-jobs-toc="v2">[【WindowsOS】HEIC2Jpg.cmd](<./【WindowsOS】HEIC2Jpg.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** HEIC转换JPEG。

- 可选install经winget安装/升级ImageMagick；使用支持HEIC的[**ImageMagick**](https://imagemagick.org/) `magick.exe`，扫描选择目录第一层HEIC，YES后输出JPEG子目录。保留原图，已有目标跳过，临时转换成功才发布，失败汇总非零退出；可用winget安装ImageMagick.ImageMagick。
- [PowerShell入口](<./【WindowsOS】HEIC2Jpg.ps1>)；只读检查：`& .\【WindowsOS】HEIC2Jpg.ps1 -Check`。

### <span id="jobs-toc-heading-10" data-jobs-toc="v2">[【WindowsOS】Java环境配置.cmd](<./【WindowsOS】Java环境配置.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** Java检查与用户配置。

- check实际检查[**Java**](https://www.java.com/) `java/javac`；install通过winget安装Eclipse Temurin21。configure选择JDK后备份用户JAVA_HOME/Path并YES持久设置；restore核对没有后续修改再恢复，不修改系统变量。安装后重开终端复检。
- [PowerShell入口](<./【WindowsOS】Java环境配置.ps1>)；只读检查：`& .\【WindowsOS】Java环境配置.ps1 -Check`。

### <span id="jobs-toc-heading-11" data-jobs-toc="v2">[【WindowsOS】PHP与Apache.cmd](<./【WindowsOS】PHP与Apache.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** PHP与Apache服务。

- 使用Docker官方php:8.4-apache，支持install / start / stop / status / logs / remove。只读挂载选定网站目录，回环8082，检查Apache配置与HTTP响应；停止移除保留网站文件。网站目录需提供可访问首页。
- [PowerShell入口](<./【WindowsOS】PHP与Apache.ps1>)；只读检查：`& .\【WindowsOS】PHP与Apache.ps1 -Check`。

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">[【WindowsOS】Tomcat.cmd](<./【WindowsOS】Tomcat.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** Tomcat服务。

- 使用Docker官方tomcat:10.1-jdk21-temurin，支持install / start / stop / status / logs / remove。将选择的webapps内容复制到独立持久数据卷，支持WAR自动展开并保留主机源文件，回环8083，catalina version复检后等待首页；需提供ROOT应用首页，否则HTTP404会如实报告未就绪。移除容器保留部署数据卷。
- [PowerShell入口](<./【WindowsOS】Tomcat.ps1>)；只读检查：`& .\【WindowsOS】Tomcat.ps1 -Check`。

### <span id="jobs-toc-heading-13" data-jobs-toc="v2">[【WindowsOS】网页视频下载.cmd](<./【WindowsOS】网页视频下载.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** 网页视频下载。

- download检查用户Python、验证HTTP/HTTPS地址并选择输出目录，显示脱敏来源，YES后运行python -m you_get；install经YES通过用户pip安装/升级you-get。仅下载本人有权使用的媒体，需要合并时先准备ffmpeg.exe。
- [PowerShell入口](<./【WindowsOS】网页视频下载.ps1>)；只读检查：`& .\【WindowsOS】网页视频下载.ps1 -Check`。

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">[【WindowsOS】RubyGems.cmd](<./【WindowsOS】RubyGems.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** RubyGems检查与维护。

- 显示[**RubyGems**](https://rubygems.org/)版本与当前软件源，支持status / source / update / cleanup。软件源只从官方或Ruby China二选一，先备份.gemrc再YES修改；更新RubyGems/Gem和清理旧版本分别确认；DevKit/编译器由既有RubyInstaller环境提供。
- [PowerShell入口](<./【WindowsOS】RubyGems.ps1>)；只读检查：`& .\【WindowsOS】RubyGems.ps1 -Check`。

### <span id="jobs-toc-heading-15" data-jobs-toc="v2">[【WindowsOS】Ruby环境升级.cmd](<./【WindowsOS】Ruby环境升级.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** Ruby环境安装升级。

- winget列出RubyInstaller当前目录，由用户复制精确RubyInstallerTeam版本包ID后YES执行安装/升级；不猜测新版本、不覆盖未知Ruby管理器，完成后重开终端验证ruby/gem。
- [PowerShell入口](<./【WindowsOS】Ruby环境升级.ps1>)；只读检查：`& .\【WindowsOS】Ruby环境升级.ps1 -Check`。

### <span id="jobs-toc-heading-16" data-jobs-toc="v2">[【WindowsOS】受保护文件追加.cmd](<./【WindowsOS】受保护文件追加.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** 受保护文件追加。

- 选择唯一普通UTF-8文件，输入一行正文；YES后同目录备份，校验无并发改变后追加并保留BOM。内容不写日志；权限不足时停止，需用户自行管理员方式启动，工具不自动提权。
- [PowerShell入口](<./【WindowsOS】受保护文件追加.ps1>)；只读检查：`& .\【WindowsOS】受保护文件追加.ps1 -Check`。

### <span id="jobs-toc-heading-17" data-jobs-toc="v2">[【WindowsOS】文件扩展名显示.cmd](<./【WindowsOS】文件扩展名显示.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** 资源管理器扩展名显示。

- Windows没有Finder逐文件隐藏扩展名属性。明确展示全局范围后，可hide/show设置当前用户Explorer HideFileExt，YES确认并保存原值；保留真实文件名，不重命名。重新打开资源管理器窗口后查看，运行反向选项恢复。
- [PowerShell入口](<./【WindowsOS】文件扩展名显示.ps1>)；只读检查：`& .\【WindowsOS】文件扩展名显示.ps1 -Check`。

### <span id="jobs-toc-heading-18" data-jobs-toc="v2">[【WindowsOS】Docker配置.cmd](<./【WindowsOS】Docker配置.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** Docker Desktop安装与检查。

- check分别检查CLI与引擎；install经YES用winget安装/升级Docker.DockerDesktop；open确认后启动Desktop。WSL2、虚拟化、许可与重启按官方引导本人完成，不静默改系统功能。
- [PowerShell入口](<./【WindowsOS】Docker配置.ps1>)；只读检查：`& .\【WindowsOS】Docker配置.ps1 -Check`。

## <span id="jobs-toc-heading-19" data-jobs-toc="v2">三、平台差异与验证 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

15个原MacOS主脚本均有Windows对应入口。Homebrew环境管理转为winget或既有用户工具链；MySQL、Apache/PHP、Tomcat采用Docker Desktop Linux容器隔离，需预先完成官方WSL2/虚拟化准备；容器安装、启动、停止、状态、移除均有明确操作，数据与源文件保留。Finder逐文件隐藏后缀只能明确适配为Explorer当前用户全局显示开关；不会删除真实文件扩展名。分类目录内Go示例、数据库说明和图片资料保留在MacOS，未改写第三方依赖。

来源：[Docker运行参数](https://docs.docker.com/reference/cli/docker/container/run/)、[MySQL官方镜像](https://hub.docker.com/_/mysql)、[PHP官方镜像](https://hub.docker.com/_/php)、[Tomcat官方镜像](https://hub.docker.com/_/tomcat)。

已进行PowerShell解析/BOM检查、只读入口检查，以及临时文件中的隔离验证；这些结果不代表Windows PowerShell 5.1实机、安装器、WSL2、数据库或服务已实际验收。未运行真实安装、升级、系统配置、服务启动、数据库重置或文件清理。

持续回归入口与范围见 [环境与服务隔离测试](./Tests/README.md)。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

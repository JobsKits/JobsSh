# `JobsSh.sh`

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#jobs-toc-heading-1)
- [一、目录结构](#repository-layout)
- [二、脚本执行流程](#script-workflows)
  - [【MacOS】JobsSql.sh](#jobs-toc-heading-4)
  - [【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh](#jobs-toc-heading-5)
  - [【MacOS】删除brew-MySql数据库并重置密码为空.sh](#jobs-toc-heading-6)
  - [【MacOS】完全删除以brew方式安装的Mysql.sh](#jobs-toc-heading-7)
  - [【MacOS】GoProject.sh](#jobs-toc-heading-8)
  - [【MacOS】HEIC2Jpg.sh](#jobs-toc-heading-9)
  - [【MacOS】Java的环境配置.sh](#jobs-toc-heading-10)
  - [【MacOS】PhpApacheConfig.sh](#jobs-toc-heading-11)
  - [【MacOS】Tomcat\_Config.sh](#jobs-toc-heading-12)
  - [【MacOS】下载网页中无法下载的视频.sh](#jobs-toc-heading-13)
  - [【MacOS】关于Gem.sh](#jobs-toc-heading-14)
  - [【MacOS】升级Ruby环境.sh](#jobs-toc-heading-15)
  - [【MacOS】向系统受保护区域文件末尾追加写入内容.sh](#jobs-toc-heading-16)
  - [【MacOS】批量隐藏某文件夹下的文件后缀名.sh](#jobs-toc-heading-17)
  - [【MacOS】配置Docker.sh](#jobs-toc-heading-18)
- [三、运行与验证边界](#verification-and-safety)

</details>
<!-- jobs-toc:end -->

---

## <span id="jobs-toc-heading-1" data-jobs-toc="v2">🔥 <font id=前言>前言</font></span><!-- jobs-toc:heading-end -->

保留的 [**macOS**](https://www.apple.com/macos/) [**Zsh**](https://www.zsh.org/) 环境、服务和文件处理入口。 每个独立脚本按其内置自述和源码定位目标；先阅读流程，确认路径后再运行。

入口统一先显示内置用途和影响范围，再等待回车确认。安装、升级直接回车跳过，非空输入执行；卸载、删除、数据重置及敏感配置必须精确输入 `YES`。无交互输入或 EOF 停止，依赖失败不继续后续业务。

| 检查项 | 当前行为 |
| --- | --- |
| 脚本与入口 | 15 个独立文本脚本，6 个分类相对链接（其中 MySQL 是目录导航）；依据 [**Git**](https://git-scm.com/) 跟踪清单及文件类型，统计日期 2026-10-22。 |
| 运行环境 | macOS 内置 `/bin/zsh`；按实际业务复用或选择安装 [**Homebrew**](https://brew.sh/) 等工具链。 |
| 路径与副本 | 脚本资源按自身真实路径定位；分类入口指向仓内主实现，移动仓库后仍可解析。 |
| 数据保护 | 图片不覆盖既有输出；工程不覆盖既有目录；系统配置和数据库变更先保留备份。 |
| 日志与失败 | 自述确认后创建私有日志；URL 凭据与查询参数在展示中脱敏，失败返回非零退出码。 |

上层 `JobsGenesis` 的实际登记如下，`path` 是本地目录，`url` 使用真实远端仓名：

```ini
[submodule "JobsSh.sh"]
    path = JobsSh.sh
    url = ../JobsSh.git
    branch = main
```

| 父仓线路 | 本仓解析地址 |
| --- | --- |
| `ssh://git@github.com/JobsKits/JobsGenesis.git` | `ssh://git@github.com/JobsKits/JobsSh.git` |
| `git@gitee.com:JobsGo/JobsGenesis.git` | `git@gitee.com:JobsGo/JobsSh.git` |

相对地址跟随父仓线路；目标平台必须已有本仓及父仓固定指针引用的提交。

## 一、<span id="repository-layout">目录结构</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

下面按当前磁盘第一层列出真实文件与目录；包内主脚本由下方完整名称直接进入。

```text
JobsSh.sh/
├── README.md
├── Mysql.sh/  # 4 个入口
├── icon.png
├── 【MacOS】Apache.sh/
├── 【MacOS】Databases/
├── 【MacOS】Docker.sh/
├── 【MacOS】GoProject.sh/  # 1 个入口
├── 【MacOS】Golang.sh/
├── 【MacOS】HEIC2Jpg.sh/  # 1 个入口
├── 【MacOS】Java.sh/
├── 【MacOS】Java的环境配置.sh/  # 1 个入口
├── 【MacOS】PhpApacheConfig.sh/  # 1 个入口
├── 【MacOS】Tomcat.sh/
├── 【MacOS】Tomcat_Config.sh/  # 1 个入口
├── 【MacOS】下载网页中无法下载的视频.sh/  # 1 个入口
├── 【MacOS】关于Gem.sh/  # 1 个入口
├── 【MacOS】升级Ruby环境.sh/  # 1 个入口
├── 【MacOS】向系统受保护区域文件末尾追加写入内容.sh/  # 1 个入口
├── 【MacOS】批量隐藏某文件夹下的文件后缀名.sh/  # 1 个入口
└── 【MacOS】配置Docker.sh/  # 1 个入口
```

## 二、<span id="script-workflows">脚本执行流程</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

本仓共有 15 个主脚本入口，按 Git 跟踪的普通文本 `.sh` 计数，分类链接不重复计入（2026-10-22）。下方列出实际职责和执行顺序；配套 README 说明参数、风险和恢复方式。静态检查与隔离假命令验证不代表真实安装或服务启动已经验收。

### <span id="jobs-toc-heading-4" data-jobs-toc="v2">[【MacOS】JobsSql.sh](./Mysql.sh/%E3%80%90MacOS%E3%80%91JobsSql.sh/%E3%80%90MacOS%E3%80%91JobsSql.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 按实际安装状态检查、安装或升级 Homebrew [**MySQL**](https://www.mysql.com/)，保留现有数据库与认证配置。

- 展示内置自述并确认，验证 Homebrew，按选择更新其软件目录。
- 选择已有 MySQL 公式或安装当前 `mysql`；升级先确认，失败停止。
- 显示安装信息，按选择启动或重启服务，并可进入交互登录；不持久开启 `skip-grant-tables`。

### <span id="jobs-toc-heading-5" data-jobs-toc="v2">[【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh](./Mysql.sh/%E3%80%90MacOS%E3%80%91%E4%BF%AE%E6%94%B9Mysql%E7%9A%84%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%EF%BC%9Amy.cnf%E3%80%90%E4%BF%AE%E6%94%B9%E5%90%8E%E5%86%8D%E8%BF%90%E8%A1%8C%E3%80%91.sh/%E3%80%90MacOS%E3%80%91%E4%BF%AE%E6%94%B9Mysql%E7%9A%84%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%EF%BC%9Amy.cnf%E3%80%90%E4%BF%AE%E6%94%B9%E5%90%8E%E5%86%8D%E8%BF%90%E8%A1%8C%E3%80%91.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 编辑、验证并备份应用 Homebrew MySQL 的配置文件。

- 确认已有 Homebrew 与所选 MySQL 公式，定位实际前缀下的配置。
- 在临时副本编辑，并使用当前 MySQL 校验配置；精确输入 `YES` 后才备份应用。
- 可选重启验证；失败恢复原配置与服务状态，日志保留备份位置。

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">[【MacOS】删除brew-MySql数据库并重置密码为空.sh](./Mysql.sh/%E3%80%90MacOS%E3%80%91%E5%88%A0%E9%99%A4brew-MySql%E6%95%B0%E6%8D%AE%E5%BA%93%E5%B9%B6%E9%87%8D%E7%BD%AE%E5%AF%86%E7%A0%81%E4%B8%BA%E7%A9%BA.sh/%E3%80%90MacOS%E3%80%91%E5%88%A0%E9%99%A4brew-MySql%E6%95%B0%E6%8D%AE%E5%BA%93%E5%B9%B6%E9%87%8D%E7%BD%AE%E5%AF%86%E7%A0%81%E4%B8%BA%E7%A9%BA.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 保留旧数据目录后重建本机 MySQL，实连验证 root 空密码。

- 确认实际数据目录为默认目录且仅回环监听；自定义目录或不安全配置停止。
- 精确输入 `YES` 后停止服务，将旧数据整目录移到唯一备份位置，再初始化新数据。
- 启动后使用本地 socket 验证 root 空密码及数据目录；失败恢复旧目录，成功后保留旧数据备份。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">[【MacOS】完全删除以brew方式安装的Mysql.sh](./Mysql.sh/%E3%80%90MacOS%E3%80%91%E5%AE%8C%E5%85%A8%E5%88%A0%E9%99%A4%E4%BB%A5brew%E6%96%B9%E5%BC%8F%E5%AE%89%E8%A3%85%E7%9A%84Mysql.sh/%E3%80%90MacOS%E3%80%91%E5%AE%8C%E5%85%A8%E5%88%A0%E9%99%A4%E4%BB%A5brew%E6%96%B9%E5%BC%8F%E5%AE%89%E8%A3%85%E7%9A%84Mysql.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 卸载选定 Homebrew MySQL，并独立选择是否删除默认数据目录。

- 检查 Homebrew 和所选 MySQL 公式，显示数据目录和服务影响。
- 精确输入 `YES` 后才停止并卸载所选版本。
- 数据删除另需一次精确 `YES`，并重新检查其它版本、运行进程与目录边界；回车保留数据。

### <span id="jobs-toc-heading-8" data-jobs-toc="v2">[【MacOS】GoProject.sh](./%E3%80%90MacOS%E3%80%91GoProject.sh/%E3%80%90MacOS%E3%80%91GoProject.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 创建 [**Go**](https://go.dev/) module 与 [**Gin**](https://gin-gonic.com/) 示例，按选择下载依赖、校验和运行。

- 复用健康 Go 和 Homebrew；安装、修复或升级均需非空输入。
- 输入父目录、工程名、module 和源码名，拒绝已有目标，生成 `/ping` 模板与环境说明。
- 先可选 `go mod tidy` 和 `go test`，成功后才可选择前台运行；可选打开已有编辑器，不改 GOPATH。

### <span id="jobs-toc-heading-9" data-jobs-toc="v2">[【MacOS】HEIC2Jpg.sh](./%E3%80%90MacOS%E3%80%91HEIC2Jpg.sh/%E3%80%90MacOS%E3%80%91HEIC2Jpg.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 将一个或多个目录中的 HEIC 转成 JPEG，保留原图与已有目标。

- 选择多个输入目录和一个输出目录；输出默认首个输入目录下的 `JPEG`。
- 仅处理第一层 HEIC，用 NUL 清单兼容中文、空格、换行文件名。
- 临时转换成功后发布新 JPEG；已存在则跳过，输出汇总并保留失败状态。

### <span id="jobs-toc-heading-10" data-jobs-toc="v2">[【MacOS】Java的环境配置.sh](./%E3%80%90MacOS%E3%80%91Java%E7%9A%84%E7%8E%AF%E5%A2%83%E9%85%8D%E7%BD%AE.sh/%E3%80%90MacOS%E3%80%91Java%E7%9A%84%E7%8E%AF%E5%A2%83%E9%85%8D%E7%BD%AE.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 检测并选择安装 [**OpenJDK**](https://openjdk.org/)，按确认配置 [**Java**](https://www.java.com/) 环境。

- 检查现有 Java 与编译器，按选择准备 Homebrew。
- 从实际可用公式选择 JDK 主版本，按健康状态安装、升级或修复并复检。
- 只有精确输入 `YES` 才备份并写入当前用户 Shell 的 Java 受控配置块，当前进程同步生效。

### <span id="jobs-toc-heading-11" data-jobs-toc="v2">[【MacOS】PhpApacheConfig.sh](./%E3%80%90MacOS%E3%80%91PhpApacheConfig.sh/%E3%80%90MacOS%E3%80%91PhpApacheConfig.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 通过 Homebrew 准备 [**PHP**](https://www.php.net/) 与 [**Apache HTTP Server**](https://httpd.apache.org/)，验证配置后管理服务。

- 按实际前缀检查 PHP、httpd，缺失或损坏时选择安装或修复。
- 检查原配置，再构造并验证 PHP 模块受控块；精确 `YES` 后备份写入，失败恢复。
- 另经 `YES` 确认才启动或重启用户 Apache 登录服务；实际网站响应另行核对。

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">[【MacOS】Tomcat_Config.sh](./%E3%80%90MacOS%E3%80%91Tomcat_Config.sh/%E3%80%90MacOS%E3%80%91Tomcat_Config.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 检测、安装并管理真正的 Homebrew [**Tomcat**](https://tomcat.apache.org/) 服务。

- 检查 Homebrew、Tomcat 和 Java，按选择安装或升级，使用 `catalina version` 复检。
- 回车只查服务；输入 `start` 启动并注册用户登录服务，输入 `stop` 停止并取消注册。
- 查询操作后状态，显示配置位置；HTTP 端口与响应依据实际配置验证。

### <span id="jobs-toc-heading-13" data-jobs-toc="v2">[【MacOS】下载网页中无法下载的视频.sh](./%E3%80%90MacOS%E3%80%91%E4%B8%8B%E8%BD%BD%E7%BD%91%E9%A1%B5%E4%B8%AD%E6%97%A0%E6%B3%95%E4%B8%8B%E8%BD%BD%E7%9A%84%E8%A7%86%E9%A2%91.sh/%E3%80%90MacOS%E3%80%91%E4%B8%8B%E8%BD%BD%E7%BD%91%E9%A1%B5%E4%B8%AD%E6%97%A0%E6%B3%95%E4%B8%8B%E8%BD%BD%E7%9A%84%E8%A7%86%E9%A2%91.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 使用 [**you-get**](https://github.com/soimort/you-get) 下载受支持网页的视频，指定本地输出目录。

- 先确认自述，收集并验证 HTTP / HTTPS URL 和输出目录，也支持两个位置参数。
- 验证 Homebrew 和小写 `you-get`，按选择安装、修复或升级；可选准备 [**FFmpeg**](https://ffmpeg.org/) 合并媒体。
- 显示脱敏来源后下载到所选目录，默认脚本旁 `Downloads`；失败保留部分文件和退出码。

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">[【MacOS】关于Gem.sh](./%E3%80%90MacOS%E3%80%91%E5%85%B3%E4%BA%8EGem.sh/%E3%80%90MacOS%E3%80%91%E5%85%B3%E4%BA%8EGem.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 检查 [**RubyGems**](https://rubygems.org/)，按确认配置用户软件源并更新用户 [**Ruby**](https://www.ruby-lang.org/) 环境。

- 健康检查 Ruby、Gem 和当前软件源，识别系统 Ruby 保护边界。
- 回车保留软件源；选择官方或 Ruby China 后，另需 `YES` 才备份并保存用户配置。
- 用户工具链可逐项选择更新 RubyGems 和 Gem；旧版清理需 `YES`，系统 Ruby 不执行升级。

### <span id="jobs-toc-heading-15" data-jobs-toc="v2">[【MacOS】升级Ruby环境.sh](./%E3%80%90MacOS%E3%80%91%E5%8D%87%E7%BA%A7Ruby%E7%8E%AF%E5%A2%83.sh/%E3%80%90MacOS%E3%80%91%E5%8D%87%E7%BA%A7Ruby%E7%8E%AF%E5%A2%83.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 沿当前 Ruby 管理来源升级，并保护系统 Ruby。

- 识别真实 Ruby 路径及 rbenv / Homebrew 归属，不以命令存在直接调用 `sudo gem update`。
- 按选择通过现有 rbenv 安装稳定版本，或通过 Homebrew 安装、修复或升级 Ruby。
- 用户默认版本或 Shell PATH 持久修改另需 `YES`，先备份，完成后复检；未知管理器保留原状。

### <span id="jobs-toc-heading-16" data-jobs-toc="v2">[【MacOS】向系统受保护区域文件末尾追加写入内容.sh](./%E3%80%90MacOS%E3%80%91%E5%90%91%E7%B3%BB%E7%BB%9F%E5%8F%97%E4%BF%9D%E6%8A%A4%E5%8C%BA%E5%9F%9F%E6%96%87%E4%BB%B6%E6%9C%AB%E5%B0%BE%E8%BF%BD%E5%8A%A0%E5%86%99%E5%85%A5%E5%86%85%E5%AE%B9.sh/%E3%80%90MacOS%E3%80%91%E5%90%91%E7%B3%BB%E7%BB%9F%E5%8F%97%E4%BF%9D%E6%8A%A4%E5%8C%BA%E5%9F%9F%E6%96%87%E4%BB%B6%E6%9C%AB%E5%B0%BE%E8%BF%BD%E5%8A%A0%E5%86%99%E5%85%A5%E5%86%85%E5%AE%B9.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 备份后向明确选择的普通文件追加一行文本。

- 选择唯一现有文件，读取追加内容；拒绝直接符号链接、多硬链接和空内容。
- 精确 `YES` 后才按需请求权限，保留同目录原文备份，临时副本中追加。
- 核对目标无并发变化后原子写回并校验；日志记录备份恢复位置，追加内容不写日志。

### <span id="jobs-toc-heading-17" data-jobs-toc="v2">[【MacOS】批量隐藏某文件夹下的文件后缀名.sh](./%E3%80%90MacOS%E3%80%91%E6%89%B9%E9%87%8F%E9%9A%90%E8%97%8F%E6%9F%90%E6%96%87%E4%BB%B6%E5%A4%B9%E4%B8%8B%E7%9A%84%E6%96%87%E4%BB%B6%E5%90%8E%E7%BC%80%E5%90%8D.sh/%E3%80%90MacOS%E3%80%91%E6%89%B9%E9%87%8F%E9%9A%90%E8%97%8F%E6%9F%90%E6%96%87%E4%BB%B6%E5%A4%B9%E4%B8%8B%E7%9A%84%E6%96%87%E4%BB%B6%E5%90%8E%E7%BC%80%E5%90%8D.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 隐藏或恢复 [**Finder**](https://support.apple.com/guide/mac-help/get-to-know-the-finder-mchlp2605/mac) 文件扩展名显示，保留真实文件名与内容。

- 拖入多个目录，验证 SetFile；回车隐藏，输入 `show` 恢复。
- NUL 遍历普通文件，跳过 `.git`、`node_modules`、`Pods`、`.dart_tool`、`build` 和 `DerivedData`。
- 逐项记录实际结果；空目录明确提示，有失败最终返回非零。

### <span id="jobs-toc-heading-18" data-jobs-toc="v2">[【MacOS】配置Docker.sh](./%E3%80%90MacOS%E3%80%91%E9%85%8D%E7%BD%AEDocker.sh/%E3%80%90MacOS%E3%80%91%E9%85%8D%E7%BD%AEDocker.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 按选择安装或升级 [**Docker Desktop**](https://docs.docker.com/desktop/)，分别检查 CLI 与引擎。

- 先查找现有 Desktop 和健康 CLI；可复用其它已配置的 Docker 环境。
- 选择后通过当前官方 `docker-desktop` Cask 安装或升级，默认用户应用目录，非用户目录另需 `YES`。
- 引擎连接检查有截止时间；未就绪时可选打开 Desktop 后复检，不以 CLI 存在声称服务已就绪。

## 三、<span id="verification-and-safety">运行与验证边界</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

在各脚本包目录运行对应入口，例如：

```shell
zsh ./【MacOS】HEIC2Jpg.sh
```

脚本的运行自述直接写在源码中，README 面向运行前阅读。所有路径输入先核对实际目标，取消可用 `Ctrl+C`；分类符号链接复用主脚本的同一次自述和确认。MySQL 分类目录链接只用于进入四个独立脚本包。

- Homebrew 已健康则复用，不因运行脚本升级所有软件；确需安装时精确 `YES` 选择系统目录，其它输入选择用户目录，另经普通安装确认后执行，选择失败不切换路径。实际安装顺序以各入口提示为准。
- 数据重置、卸载、配置、服务注册均按入口的具体确认提示执行；备份位置记录在日志中，恢复前先检查是否有后续变更。
- 日志位于系统临时目录，名称为脚本去除 `.sh` 后加 `.log`；自述显示实际位置。URL 展示副本脱敏，实际业务地址保持原样。
- 验证使用 `zsh -n`、临时目录及假工具覆盖确认、失败、备份恢复、特殊路径与依赖修复，不执行真实软件安装、数据库清理或系统服务变更。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

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

</details>
<!-- jobs-toc:end -->

---

## <span id="jobs-toc-heading-1" data-jobs-toc="v2">🔥 <font id=前言>前言</font></span><!-- jobs-toc:heading-end -->

保留的 macOS Shell 环境、服务和文件处理入口。 每个独立脚本按其内置自述和源码定位目标；先阅读流程，确认路径后再运行。

部分旧入口仍带固定用户目录、版本号或破坏性默认值，必须先核对源码再使用；此处按实际逻辑说明，不表示已验证可在当前系统直接执行。

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

本仓共有 15 个用户入口。这里只列本仓维护的主入口；独立子 Git、测试、函数库及打包资源模板不作为用户运行入口。步骤来自静态源码与配套说明，未执行安装、清理、构建或 Git 写操作。

### <span id="jobs-toc-heading-4" data-jobs-toc="v2">[【MacOS】JobsSql.sh](./Mysql.sh/%E3%80%90MacOS%E3%80%91JobsSql.sh/%E3%80%90MacOS%E3%80%91JobsSql.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 按旧预设重装 MySQL 并准备配置与登录。

- 先核对源码中 MySQL 固定版本目录及数据保留需求。
- 停止服务，按清理提示决定是否卸载，再尝试安装 MySQL。
  - 提示约定为回车跳过清理、非空输入才清理；当前旧条件写法仍需运行前核查。
- 在预设配置中补入 `skip-grant-tables`，复制到系统配置后启动服务并进入登录命令；会改变数据库认证行为。

### <span id="jobs-toc-heading-5" data-jobs-toc="v2">[【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh](./Mysql.sh/%E3%80%90MacOS%E3%80%91%E4%BF%AE%E6%94%B9Mysql%E7%9A%84%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%EF%BC%9Amy.cnf%E3%80%90%E4%BF%AE%E6%94%B9%E5%90%8E%E5%86%8D%E8%BF%90%E8%A1%8C%E3%80%91.sh/%E3%80%90MacOS%E3%80%91%E4%BF%AE%E6%94%B9Mysql%E7%9A%84%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%EF%BC%9Amy.cnf%E3%80%90%E4%BF%AE%E6%94%B9%E5%90%8E%E5%86%8D%E8%BF%90%E8%A1%8C%E3%80%91.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 替换 MySQL 的 my.cnf 并重启。

- 先修改源码中的配置约定，确认后停止 MySQL 服务。
- 读取安装版本，将对应配置复制到 /etc/my.cnf。
- 重启服务并进入登录验证；系统配置覆盖可能需要管理员权限。

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">[【MacOS】删除brew-MySql数据库并重置密码为空.sh](./Mysql.sh/%E3%80%90MacOS%E3%80%91%E5%88%A0%E9%99%A4brew-MySql%E6%95%B0%E6%8D%AE%E5%BA%93%E5%B9%B6%E9%87%8D%E7%BD%AE%E5%AF%86%E7%A0%81%E4%B8%BA%E7%A9%BA.sh/%E3%80%90MacOS%E3%80%91%E5%88%A0%E9%99%A4brew-MySql%E6%95%B0%E6%8D%AE%E5%BA%93%E5%B9%B6%E9%87%8D%E7%BD%AE%E5%AF%86%E7%A0%81%E4%B8%BA%E7%A9%BA.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 重装 MySQL 并按旧流程重建数据库配置。

- 停止、卸载当前 MySQL，核对固定的数据目录。
- 按提示决定是否删除数据库，再重新安装。
  - 该数据删除提示直接回车会删除；输入非空内容才跳过。
- 复制配置并重启，随后人工核对账户和密码状态；数据删除不可撤销。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">[【MacOS】完全删除以brew方式安装的Mysql.sh](./Mysql.sh/%E3%80%90MacOS%E3%80%91%E5%AE%8C%E5%85%A8%E5%88%A0%E9%99%A4%E4%BB%A5brew%E6%96%B9%E5%BC%8F%E5%AE%89%E8%A3%85%E7%9A%84Mysql.sh/%E3%80%90MacOS%E3%80%91%E5%AE%8C%E5%85%A8%E5%88%A0%E9%99%A4%E4%BB%A5brew%E6%96%B9%E5%BC%8F%E5%AE%89%E8%A3%85%E7%9A%84Mysql.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 卸载 Homebrew MySQL，并可删除本地数据。

- 检查 Homebrew 环境后停止 MySQL 服务。
- 卸载 MySQL 并打开配置的数据库目录。
- 按提示决定是否删除数据目录。
  - 当前旧入口在该提示处直接回车会删除数据；保留数据需按源码提示输入非空内容。

### <span id="jobs-toc-heading-8" data-jobs-toc="v2">[【MacOS】GoProject.sh](./%E3%80%90MacOS%E3%80%91GoProject.sh/%E3%80%90MacOS%E3%80%91GoProject.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 按旧模板创建 Go / Gin 示例工程并尝试运行。

- 检查源码中的路径和旧工具命令，确认后准备 Homebrew。
- 输入工程和文件名，创建目录、初始化 Go module，并写入 Gin 示例。
  - 源码虽定义 Go / IDE 安装函数，但主流程没有调用，运行前需已有 Go 和编辑器等工具。
- 尝试运行示例，后续按顺序下载依赖、生成环境说明，并按检测结果追加 GOPATH 配置。

### <span id="jobs-toc-heading-9" data-jobs-toc="v2">[【MacOS】HEIC2Jpg.sh](./%E3%80%90MacOS%E3%80%91HEIC2Jpg.sh/%E3%80%90MacOS%E3%80%91HEIC2Jpg.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 批量将源码指定目录中的 HEIC 转为 JPEG。

- 运行前核对并修改源码固定的桌面输入 2 和输出 3 目录。
- 确认后创建输出目录，逐项查找输入 HEIC。
- 使用 sips 生成同名 JPEG，原 HEIC 保留。

### <span id="jobs-toc-heading-10" data-jobs-toc="v2">[【MacOS】Java的环境配置.sh](./%E3%80%90MacOS%E3%80%91Java%E7%9A%84%E7%8E%AF%E5%A2%83%E9%85%8D%E7%BD%AE.sh/%E3%80%90MacOS%E3%80%91Java%E7%9A%84%E7%8E%AF%E5%A2%83%E9%85%8D%E7%BD%AE.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 按旧脚本流程准备 JDK 环境。

- 先核对源码的预设路径、版本与下载网址，确认后检查 Homebrew。
- 按提示选择 JDK 与下载工具，执行下载和目录打开动作。
- 检查输出的安装路径并处理 Shell 配置，人工验证 Java；旧下载模板需先核实可用。

### <span id="jobs-toc-heading-11" data-jobs-toc="v2">[【MacOS】PhpApacheConfig.sh](./%E3%80%90MacOS%E3%80%91PhpApacheConfig.sh/%E3%80%90MacOS%E3%80%91PhpApacheConfig.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 通过 Homebrew 准备 PHP 与 Apache 服务。

- 检查源码版本与路径，准备 Homebrew。
- 安装 PHP、OpenSSL 和 httpd，处理预设配置。
- 启动或重启服务并打开本机访问地址，按输出检查多版本 PHP 配置。

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">[【MacOS】Tomcat_Config.sh](./%E3%80%90MacOS%E3%80%91Tomcat_Config.sh/%E3%80%90MacOS%E3%80%91Tomcat_Config.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 启动系统 Apache；该入口名保留旧 Tomcat 字样。

- 查看内置自述并确认。
- 执行 sudo apachectl start，按系统要求验证管理员身份。
- 核对 Apache 服务结果；源码没有安装或配置 Tomcat 的完整流程。

### <span id="jobs-toc-heading-13" data-jobs-toc="v2">[【MacOS】下载网页中无法下载的视频.sh](./%E3%80%90MacOS%E3%80%91%E4%B8%8B%E8%BD%BD%E7%BD%91%E9%A1%B5%E4%B8%AD%E6%97%A0%E6%B3%95%E4%B8%8B%E8%BD%BD%E7%9A%84%E8%A7%86%E9%A2%91.sh/%E3%80%90MacOS%E3%80%91%E4%B8%8B%E8%BD%BD%E7%BD%91%E9%A1%B5%E4%B8%AD%E6%97%A0%E6%B3%95%E4%B8%8B%E8%BD%BD%E7%9A%84%E8%A7%86%E9%A2%91.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 安装并调用 you-get 下载指定网页视频。

- 检查 Homebrew，准备 you-get。
- 按源码提示输入或修改目标网页地址与输出位置。
- 执行下载并查看终端结果；能否取得媒体取决于实际网页支持情况。

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">[【MacOS】关于Gem.sh](./%E3%80%90MacOS%E3%80%91%E5%85%B3%E4%BA%8EGem.sh/%E3%80%90MacOS%E3%80%91%E5%85%B3%E4%BA%8EGem.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 切换 RubyGems 软件源并更新环境。

- 显示当前 gem 源列表。
- 移除 rubygems.org，添加源码指定镜像并更新源缓存。
- 更新 RubyGems 和已安装包，再清理旧包；会影响全局 Ruby 环境。

### <span id="jobs-toc-heading-15" data-jobs-toc="v2">[【MacOS】升级Ruby环境.sh](./%E3%80%90MacOS%E3%80%91%E5%8D%87%E7%BA%A7Ruby%E7%8E%AF%E5%A2%83.sh/%E3%80%90MacOS%E3%80%91%E5%8D%87%E7%BA%A7Ruby%E7%8E%AF%E5%A2%83.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 执行源码定义的 Ruby 环境升级。

- 阅读自述，按源码顺序检查 Ruby 命令、Homebrew Ruby 和 rbenv。
  - 只要检测到 `ruby` 命令，就先执行 `sudo gem update --system`；否则依次尝试 Homebrew 升级或 rbenv 安装并切换全局版本。
- 输出所命中分支的升级结果；主流程没有调用文件中定义的 Shell 配置写入函数。

### <span id="jobs-toc-heading-16" data-jobs-toc="v2">[【MacOS】向系统受保护区域文件末尾追加写入内容.sh](./%E3%80%90MacOS%E3%80%91%E5%90%91%E7%B3%BB%E7%BB%9F%E5%8F%97%E4%BF%9D%E6%8A%A4%E5%8C%BA%E5%9F%9F%E6%96%87%E4%BB%B6%E6%9C%AB%E5%B0%BE%E8%BF%BD%E5%8A%A0%E5%86%99%E5%85%A5%E5%86%85%E5%AE%B9.sh/%E3%80%90MacOS%E3%80%91%E5%90%91%E7%B3%BB%E7%BB%9F%E5%8F%97%E4%BF%9D%E6%8A%A4%E5%8C%BA%E5%9F%9F%E6%96%87%E4%BB%B6%E6%9C%AB%E5%B0%BE%E8%BF%BD%E5%8A%A0%E5%86%99%E5%85%A5%E5%86%85%E5%AE%B9.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 通过桌面副本向指定受保护文件追加内容。

- 运行前编辑源码中的目标文件与待追加文本。
- 复制文件到脚本预设的桌面位置并修改副本。
- 按源码流程复制回目标位置，人工核对权限及原文件备份。

### <span id="jobs-toc-heading-17" data-jobs-toc="v2">[【MacOS】批量隐藏某文件夹下的文件后缀名.sh](./%E3%80%90MacOS%E3%80%91%E6%89%B9%E9%87%8F%E9%9A%90%E8%97%8F%E6%9F%90%E6%96%87%E4%BB%B6%E5%A4%B9%E4%B8%8B%E7%9A%84%E6%96%87%E4%BB%B6%E5%90%8E%E7%BC%80%E5%90%8D.sh/%E3%80%90MacOS%E3%80%91%E6%89%B9%E9%87%8F%E9%9A%90%E8%97%8F%E6%9F%90%E6%96%87%E4%BB%B6%E5%A4%B9%E4%B8%8B%E7%9A%84%E6%96%87%E4%BB%B6%E5%90%8E%E7%BC%80%E5%90%8D.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 批量修改 Finder 的文件扩展名显示属性。

- 输入目标目录并检查 SetFile 可用。
- 递归查找目标下的文件。
- 逐项设置扩展名隐藏属性，文件实际名称与内容保留。

### <span id="jobs-toc-heading-18" data-jobs-toc="v2">[【MacOS】配置Docker.sh](./%E3%80%90MacOS%E3%80%91%E9%85%8D%E7%BD%AEDocker.sh/%E3%80%90MacOS%E3%80%91%E9%85%8D%E7%BD%AEDocker.sh)</span><!-- jobs-toc:heading-end -->

> **目的：** 安装 Docker Desktop 并检查本机 Docker 状态。

- 检查 Homebrew，打开 Docker 官方安装说明。
- 安装 Docker Desktop 到源码预设的应用目录。
- 运行 docker version / info，按结果确认桌面服务是否已经启动。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

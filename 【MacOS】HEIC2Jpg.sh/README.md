# `【MacOS】HEIC2Jpg.sh`

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

使用 [**macOS**](https://www.apple.com/macos/) 自带 `sips` 将一个或多个目录中的 HEIC 转换为 JPEG。

只扫描输入目录的第一层普通 HEIC 文件，保留原图，不覆盖已有 JPEG。

| 入口速览 | 实际行为 |
| --- | --- |
| 操作顺序 | 拖入输入目录 → 选择输出目录（默认首目录下 `JPEG`）→ 转换并汇总成功 / 跳过 / 失败。 |
| 交互 | 自述回车继续；拖入输入目录后选择输出目录，已有目标自动跳过。 |
| 范围 | 只扫描输入目录的第一层普通 HEIC 文件，保留原图，不覆盖已有 JPEG。 |

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 使用 macOS 自带 `sips` 将一个或多个目录中的 HEIC 转换为 JPEG。
- 希望通过可重复运行的 Shell 脚本减少手工命令遗漏。
- 需要结合终端日志定位环境、路径或第三方工具问题。

脚本统一由 macOS 预置的 `/bin/zsh` 执行。双击或直接执行脚本即可；显式指定解释器时使用 `zsh`，不要使用 `bash` 或 `sh`。运行后先显示内置自述，确认后才进入业务；无法读取确认输入时会退出。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录结构 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```text
【MacOS】HEIC2Jpg.sh/
├── 【MacOS】HEIC2Jpg.sh
└── README.md
```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 确认当前系统为 MacOS，并已安装脚本实际调用的工具。
- 确认脚本路径、工程目录、输入文件和当前 Git 工作区正确。
- 打开主脚本检查其中的业务命令，不理解的操作不要直接执行。
- 涉及安装、更新或升级时，以脚本终端提示为准；直接回车应表示跳过。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">4.1、双击运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在 Finder 中打开当前目录并双击 `【MacOS】HEIC2Jpg.sh`。阅读终端自述后按回车继续，按 `Ctrl+C` 取消。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">4.2、终端运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在当前 README 所在目录运行：

```shell
zsh ./【MacOS】HEIC2Jpg.sh
```

## <span id="jobs-toc-heading-8" data-jobs-toc="v2">五、操作流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、展示内置自述并等待回车，确认后初始化日志。

2、拖入一个或多个目录，支持中文、空格、引号与 Finder 转义路径；仅处理第一层，不递归子目录。

3、选择一个输出目录，回车使用首个输入目录下的 `JPEG`。

4、使用 `find -print0` 遍历 HEIC，临时转换成功后才发布 `.jpg`。同名目标已存在时保留并跳过。

5、输出总数、成功数、跳过数和失败数；任一文件失败时最终返回非零状态，空目录明确提示无数据。

## <span id="jobs-toc-heading-9" data-jobs-toc="v2">六、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->


- 多个输入目录有同名 HEIC 时，后续同名输出会跳过；输出与输入可同目录，但不会覆盖文件。
- 转换结果取决于系统解码器；失败时保留原图，不发布不完整 JPEG。

## <span id="jobs-toc-heading-10" data-jobs-toc="v2">七、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

日志追加到系统临时目录中的 `【MacOS】HEIC2Jpg.log`，运行自述会显示实际位置。日志文件使用当前用户私有权限，非终端和日志均为纯文本。

## <span id="jobs-toc-heading-11" data-jobs-toc="v2">八、常见问题 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">8.1、提示命令不存在 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

根据终端错误确认缺少的工具，先完成安装并保证命令已经加入 `PATH`。

### <span id="jobs-toc-heading-13" data-jobs-toc="v2">8.2、提示权限不足 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

检查目标文件权限和目录归属。只有确认命令及目标路径安全后，才按提示使用管理员权限。

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">8.3、双击后没有继续执行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

查看终端是否正在等待阅读确认或业务输入；不确定时按 `Ctrl+C` 退出后重新检查脚本。

## <span id="jobs-toc-heading-15" data-jobs-toc="v2">九、未执行声明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

静态语法及隔离夹具验证用于检查输入、失败和文件保护分支，不代表已在当前机器执行真实安装、服务启动或系统文件写入。

输入与输出在运行时选择，源码不含固定桌面路径。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

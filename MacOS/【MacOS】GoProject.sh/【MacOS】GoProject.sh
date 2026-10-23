#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】GoProject.sh
# - 核心用途：创建 Go module 与 Gin /ping 示例，可选下载依赖、校验及运行。
# - 影响范围：只新建所选父目录下的工程；现有目录一律保留，不修改 GOPATH 或 Shell 配置。
# - 运行提示：先展示内置自述，回车继续；Ctrl+C 或 EOF 停止，危险操作要求 YES。
# shell: zsh
SCRIPT_SOURCE="${(%):-%x}"
SCRIPT_PURPOSE='创建 Go module 与 Gin /ping 示例，可选下载依赖、校验及运行。'
SCRIPT_IMPACT='只新建所选父目录下的工程；现有目录一律保留，不修改 GOPATH 或 Shell 配置。'

# 显示内置自述，确认前只计算展示路径，不创建日志或改动环境。
show_script_intro_and_wait() {
  SCRIPT_PATH="${SCRIPT_SOURCE:A}"
  SCRIPT_DIR="${SCRIPT_PATH:h}"
  SCRIPT_BASENAME="${SCRIPT_PATH:t:r}"
  LOG_FILE="${TMPDIR:-/tmp}/${SCRIPT_BASENAME}.log"
  intro_line title "================ ${SCRIPT_BASENAME} ================"
  intro_line body "核心用途：${SCRIPT_PURPOSE}"
  intro_line body "影响范围：${SCRIPT_IMPACT}"
  intro_line body "日志位置：${LOG_FILE}（确认后追加记录）"
  intro_line body '按回车继续；Ctrl+C 或输入结束取消。安装、升级另行选择，直接回车跳过。'
  [[ -t 0 ]] || { print -u2 -r -- '✖ 当前没有可交互输入，请在终端运行。'; exit 1; }
  local answer
  IFS= read -r 'answer?➤ 已了解用途与影响，按回车继续：' || exit 1
}
# 按终端能力渲染标题与正文，日志和非终端保持纯文本。
intro_line() {
  local role="$1" message="$2" style='0;34'
  [[ "$role" != title ]] || style='1;31'
  if [[ -t 1 && -n "${TERM:-}" && "${TERM:-}" != dumb && -z "${NO_COLOR+x}" ]]; then
    printf '\033[%sm%s\033[0m\n' "$style" "$message"
  else
    print -r -- "$message"
  fi
}
# 初始化当前进程选项及私有日志，不读取或改写 Shell 启动文件。
initialize_script_runtime() {
  setopt NO_NOMATCH TYPESET_SILENT ERR_EXIT PIPE_FAIL
  umask 077
  [[ ! -L "$LOG_FILE" && ( ! -e "$LOG_FILE" || ( -f "$LOG_FILE" && -O "$LOG_FILE" ) ) ]] || {
    print -u2 -r -- "✖ 日志不是当前用户的普通文件：$LOG_FILE"; exit 1
  }
  : >> "$LOG_FILE"
  chmod 600 "$LOG_FILE"
  export HOMEBREW_NO_AUTO_UPDATE=1 NO_COLOR=1 CLICOLOR=0 FORCE_COLOR=0
  log "ℹ 开始：$SCRIPT_PATH"
  [[ "$(uname -s)" == Darwin ]] || die '仅支持 macOS。'
}
# 删除展示中的 ANSI 与 URL 凭据、查询参数，实际业务参数保持原样。
sanitize_output() {
  /usr/bin/perl -pe 's/\e\[[0-9;]*[A-Za-z]//g; s{(https?://)[^/\s\@]+\@}{$1***\@}g; s{(https?://[^\s?#]+)[?#][^\s]*}{$1?[redacted]}g'
}
# 同步输出可检索日志并保留纯文本。
log() {
  print -r -- "$*" | sanitize_output | tee -a "$LOG_FILE"
}
# 报告具体失败并停止后续业务。
die() {
  log "✖ $*"
  exit 1
}
# 执行外部命令，记录脱敏输出并保留真实退出码。
run_command() {
  local result
  local -a results
  "$@" 2>&1 | sanitize_output | tee -a "$LOG_FILE"
  results=("${pipestatus[@]}")
  for result in "${results[@]}"; do
    (( result == 0 )) || return "$result"
  done
  return 0
}
# 让普通写操作显式选择，回车跳过，EOF 终止整个脚本。
ask_any_to_run() {
  local answer
  print -n -r -- "$1（回车跳过；输入任意字符执行）："
  IFS= read -r answer || die '输入结束，已停止。'
  [[ -n "$answer" ]]
}
# 保护危险操作，只有精确大写 YES 授权。
confirm_yes() {
  local answer
  print -n -r -- "⚠ $1（输入 YES 执行，其它输入取消）："
  IFS= read -r answer || die '输入结束，已停止。'
  [[ "$answer" == YES ]]
}
# 解析 Finder 拖入的多个带引号或反斜杠路径，不求值执行输入。
read_paths() {
  local raw word
  local -a words
  print -n -r -- "$1"
  IFS= read -r raw || die '输入结束，已停止。'
  words=("${(@z)raw}")
  PATH_INPUTS=()
  PATH_INPUT_RAW=()
  for word in "${words[@]}"; do
    word="${(Q)word}"
    word="${word%$'\r'}"
    [[ "$word" != '~/'* ]] || word="$HOME/${word#\~/}"
    if [[ -n "$word" ]]; then
      PATH_INPUT_RAW+=("${word:a}")
      PATH_INPUTS+=("${word:A}")
    fi
  done
}
# 在传输前说明对象、真实来源配置和目标。
show_source() {
  log "━━━━━━━━━━ 来源｜$1 ━━━━━━━━━━"
  log "对象：$2"
  log "来源：$3"
  log "目标：$4"
  log '━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
}
# 输出安装诊断，避免混入返回的命令路径。
jobs_brew_note() {
  log "ℹ $*" >&2
}
# 验证候选能够执行；共享安装只读不代表未安装。
jobs_brew_candidate_ok() {
  local candidate="$1" prefix
  [[ -n "$candidate" && -x "$candidate" ]] || return 1
  HOMEBREW_NO_AUTO_UPDATE=1 "$candidate" --version >/dev/null 2>&1 || return 1
  prefix="$("$candidate" --prefix 2>/dev/null)" || return 1
  [[ "$prefix" == /* && -d "$prefix" ]]
}
# 发现既有健康安装，不以目录可写性决定是否重新安装。
jobs_brew_find() {
  local candidate
  local -a candidates
  candidates=("${JOBS_HOMEBREW_BIN:-}" "$(command -v brew 2>/dev/null)" /opt/homebrew/bin/brew /usr/local/bin/brew
    "${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}/bin/brew" "$HOME/.homebrew/bin/brew")
  for candidate in "${candidates[@]}"; do
    if jobs_brew_candidate_ok "$candidate"; then
      print -r -- "$candidate"
      return 0
    fi
  done
  return 1
}
# 计算官方系统目录；实际支持范围和授权交由官方安装器处理。
jobs_brew_system_prefix() {
  case "$(/usr/bin/uname -m)" in
    arm64) print -r -- /opt/homebrew ;;
    *) print -r -- /usr/local ;;
  esac
}
# 缺失时强提示选择安装路径；YES 只表示选择系统目录，不验证密码或权限。
jobs_brew_choose_installation() {
  local answer="" system_prefix="$(jobs_brew_system_prefix)"
  if [[ ! -t 0 || ! -t 2 || "${IS_SOURCETREE_RUNTIME:-0}" == 1 ]]; then
    jobs_brew_note "缺少 Homebrew，需要人工选择安装路径；请在可交互终端重新运行，未执行安装。"
    return 1
  fi
  print -u2 -r -- "⚠ Homebrew 尚未就绪，必须先选择安装路径："
  print -u2 -r -- "1、输入精确大写 YES：选择系统标准目录 $system_prefix（Apple Silicon：/opt/homebrew；Intel：/usr/local）。"
  print -u2 -r -- "   这表示你准备向系统目录安装；官方安装器可能随后要求管理员密码，并自行验证权限。"
  print -u2 -r -- "2、其它输入或直接回车：选择用户目录 ${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}，不使用 sudo；有管理员权限也可选此路径。"
  print -u2 -r -- "本步骤只选择路径，不收集或验证密码；选定路径失败就停止，不自动切换。按 Ctrl+C 取消整个任务。"
  print -u2 -n -r -- "➤ 安装路径选择："
  if ! IFS= read -r answer; then
    jobs_brew_note "输入已取消或结束，停止安装。"
    return 1
  fi
  if [[ "$answer" == YES ]]; then
    typeset -g JOBS_HOMEBREW_INSTALL_MODE=system
  else
    typeset -g JOBS_HOMEBREW_INSTALL_MODE=user
  fi
}
# 将官方系统安装器下载到临时文件后执行，失败不自动改装到用户目录。
jobs_brew_install_system() {
  local installer system_prefix="$(jobs_brew_system_prefix)" installer_result=0
  command -v curl >/dev/null 2>&1 || { jobs_brew_note "缺少 curl，无法获取官方安装器。"; return 1; }
  installer="$(mktemp "${TMPDIR:-/tmp}/jobs-homebrew-install.XXXXXX")" || return 1
  show_source 下载 Homebrew安装器 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh "$installer"
  if run_command curl -fsSL --connect-timeout 10 --max-time 120 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"; then
    run_command /bin/bash "$installer" || installer_result=$?
  else
    installer_result=1
  fi
  rm -- "$installer"
  if (( installer_result != 0 )); then
    jobs_brew_note "系统目录安装失败（退出码 $installer_result）；停止，不自动切换安装路径。"
    return 1
  fi
  typeset -g JOBS_HOMEBREW_BIN="$system_prefix/bin/brew"
  jobs_brew_candidate_ok "$JOBS_HOMEBREW_BIN" || { jobs_brew_note "官方安装器结束后未找到健康 Homebrew：$JOBS_HOMEBREW_BIN"; return 1; }
}
# 克隆官方稳定版本到用户目录；不覆盖非空目录，不调用 sudo。
jobs_brew_install_user() {
  local prefix="${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}" stage release_tag git_bin
  [[ "$prefix" == /* && "$prefix" != / && "$prefix" != *[[:space:]:]* ]] || {
    jobs_brew_note "Homebrew 用户前缀须为不含空白或冒号的绝对目录：$prefix"
    return 1
  }
  if [[ -L "$prefix" || ( -e "$prefix" && ! -d "$prefix" ) || ( -d "$prefix" && -n "$(ls -A "$prefix" 2>/dev/null)" ) ]]; then
    jobs_brew_note "用户安装目标非空或不是普通目录，不覆盖：$prefix"
    return 1
  fi
  git_bin="$(command -v git 2>/dev/null)"
  [[ -n "$git_bin" ]] && "$git_bin" --version >/dev/null 2>&1 || { jobs_brew_note "用户目录安装需要可用 Git；请先准备 Git / Command Line Tools。"; return 1; }
  command -v curl >/dev/null 2>&1 || { jobs_brew_note "缺少 curl，无法获取官方稳定版本。"; return 1; }
  export HOMEBREW_NO_SUDO=1
  mkdir -p "${prefix:h}" || return 1
  stage="$(mktemp -d "${prefix:h}/.jobs-homebrew.XXXXXX")" || return 1
  show_source 下载 Homebrew稳定版 https://api.github.com/repos/Homebrew/brew/releases/latest "$stage/release.json"
  if ! run_command curl -fsSL --connect-timeout 10 --max-time 60 https://api.github.com/repos/Homebrew/brew/releases/latest -o "$stage/release.json"; then
    rm -r -- "$stage"
    jobs_brew_note "获取官方稳定版本失败，停止安装。"
    return 1
  fi
  release_tag="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "$stage/release.json" | head -n 1)"
  show_source 克隆 "Homebrew $release_tag" https://github.com/Homebrew/brew.git "$prefix"
  if [[ ! "$release_tag" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] ||
     ! run_command env GIT_TERMINAL_PROMPT=0 "$git_bin" -c http.lowSpeedLimit=1 -c http.lowSpeedTime=60 clone --depth 1 --branch "$release_tag" --single-branch https://github.com/Homebrew/brew.git "$stage/brew" ||
     ! "$git_bin" -C "$stage/brew" checkout -b stable ||
     ! "$git_bin" -C "$stage/brew" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' ||
     ! mkdir -p "$stage/brew/Cellar" "$stage/brew/Caskroom" "$stage/brew/etc" "$stage/brew/var"; then
    rm -r -- "$stage"
    jobs_brew_note "Homebrew 用户目录初始化失败，停止安装。"
    return 1
  fi
  # 空目录也只在下载成功后移除，避免提前改动用户的目标目录。
  if [[ -d "$prefix" ]] && ! rmdir -- "$prefix"; then
    rm -r -- "$stage"
    return 1
  fi
  if ! mv "$stage/brew" "$prefix"; then
    rm -r -- "$stage"
    return 1
  fi
  rm -r -- "$stage"
  typeset -g JOBS_HOMEBREW_BIN="$prefix/bin/brew"
  jobs_brew_candidate_ok "$JOBS_HOMEBREW_BIN" || { jobs_brew_note "用户目录安装后复检失败：$prefix"; return 1; }
}
# 激活当前进程并验证 Ruby 命令层；只有新安装才持久化 shellenv。
jobs_brew_activate() {
  local brew_env
  brew_env="$("$JOBS_HOMEBREW_BIN" shellenv)" || return 1
  eval "$brew_env" || return 1
  typeset -g JOBS_HOMEBREW_PREFIX="$("$JOBS_HOMEBREW_BIN" --prefix)"
  export PATH="$JOBS_HOMEBREW_PREFIX/bin:$JOBS_HOMEBREW_PREFIX/sbin:$PATH"
  rehash
  HOMEBREW_NO_AUTO_UPDATE=1 "$JOBS_HOMEBREW_BIN" config >/dev/null || { jobs_brew_note "Homebrew 命令层复检失败，停止后续业务。"; return 1; }
  if [[ "${1:-}" == installed ]]; then
    if [[ "${JOBS_HOMEBREW_INSTALL_MODE:-}" == user && -z "${HOMEBREW_CASK_OPTS:-}" ]]; then
      export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
    fi
    jobs_brew_note "Homebrew 当前进程已生效；独立工具未写 Shell 配置，后续运行会重新发现此前选择的安装位置。"
  fi
}
# 在原版安装位置复用或安装 Homebrew，安装失败必须终止外层业务。
jobs_brew_install_or_exit() {
  local installed=""
  if ! JOBS_HOMEBREW_BIN="$(jobs_brew_find)"; then
    ask_any_to_run "Homebrew 不可用，安装或修复" || die "Homebrew 未就绪，停止下游业务。"
    jobs_brew_choose_installation || exit 1
    case "$JOBS_HOMEBREW_INSTALL_MODE" in
      system) jobs_brew_install_system || exit 1 ;;
      user) jobs_brew_install_user || exit 1 ;;
      *) jobs_brew_note "安装路径选择无效，停止。"; exit 1 ;;
    esac
    installed=installed
    log "✔ Homebrew 来源：https://github.com/Homebrew/brew；安装位置：$JOBS_HOMEBREW_BIN"
  fi
  jobs_brew_activate "$installed" || exit 1
}
# 使用各工具真实支持的版本命令验证健康，Go 使用子命令 version。
tool_is_healthy() {
  local tool="$1" candidate="$2"
  [[ -n "$candidate" && -x "$candidate" ]] || return 1
  case "$tool" in
    go) "$candidate" version >/dev/null 2>&1 && command -v gofmt >/dev/null 2>&1 && gofmt -h >/dev/null 2>&1 ;;
    *) "$candidate" --version >/dev/null 2>&1 ;;
  esac
}
# 按健康状态和显式选择安装或升级当前业务依赖，不更新其它软件。
ensure_formula_tool() {
  local tool="$1" formula="$2" candidate
  candidate="$(command -v "$tool" 2>/dev/null || true)"
  if tool_is_healthy "$tool" "$candidate"; then
    log "✔ 已复用健康工具：$candidate"
    if ask_any_to_run "升级 Homebrew 管理的 $formula"; then
      "$JOBS_HOMEBREW_BIN" list --versions "$formula" >/dev/null 2>&1 || die "$tool 来自其它来源，请使用原安装方式升级。"
      show_source 升级 "$formula" 'Homebrew 当前配置的软件源（最终下载地址由 brew 解析）' "$JOBS_HOMEBREW_PREFIX"
      run_command "$JOBS_HOMEBREW_BIN" upgrade "$formula" || die "$formula 升级失败。"
    fi
  else
    ask_any_to_run "安装或修复 $formula" || die "$tool 未就绪，已停止。"
    show_source 安装 "$formula" 'Homebrew 当前配置的软件源（最终下载地址由 brew 解析）' "$JOBS_HOMEBREW_PREFIX"
    if "$JOBS_HOMEBREW_BIN" list --versions "$formula" >/dev/null 2>&1; then
      run_command "$JOBS_HOMEBREW_BIN" reinstall "$formula" || die "$formula 修复失败。"
    else
      run_command "$JOBS_HOMEBREW_BIN" install "$formula" || die "$formula 安装失败。"
    fi
  fi
  rehash
  candidate="$(command -v "$tool" 2>/dev/null || true)"
  tool_is_healthy "$tool" "$candidate" || die "$tool 安装后健康复检失败。"
}
# 验证 Go 依赖，复用健康环境或按选择仅修复当前依赖。
prepare_go_environment() {
  jobs_brew_install_or_exit
  ensure_formula_tool go go
}
# 收集工程参数并在任何生成动作前拒绝现有目标。
collect_go_project() {
  read_paths '工程父目录（回车使用脚本目录下的 GeneratedProjects）：'
  (( ${#PATH_INPUTS} <= 1 )) || die '只能指定一个父目录。'
  PROJECT_PARENT="${PATH_INPUTS[1]:-$SCRIPT_DIR/GeneratedProjects}"
  local name source_name
  IFS= read -r 'name?工程文件夹名（回车 Test）：' || die '输入结束，已停止。'
  name="${name:-Test}"
  [[ "$name" != . && "$name" != .. && "$name" != */* && "$name" != *$'\n'* ]] || die '工程名不能包含路径分隔符或换行。'
  PROJECT_DIR="$PROJECT_PARENT/$name"
  [[ ! -e "$PROJECT_DIR" && ! -L "$PROJECT_DIR" ]] || die "目标已存在，不覆盖：$PROJECT_DIR"
  IFS= read -r 'MODULE_NAME?Go module 路径（回车 example.com/demo）：' || die '输入结束，已停止。'
  MODULE_NAME="${MODULE_NAME:-example.com/demo}"
  [[ "$MODULE_NAME" =~ '^[A-Za-z0-9][A-Za-z0-9._/-]*$' && "$MODULE_NAME" != */ && "$MODULE_NAME" != *'..'* && "$MODULE_NAME" != *'//'* ]] || die 'module 路径含无效字符。'
  IFS= read -r 'source_name?源码文件名（回车 main.go）：' || die '输入结束，已停止。'
  SOURCE_NAME="${source_name:-main.go}"
  [[ "$SOURCE_NAME" =~ '^[A-Za-z][A-Za-z0-9_]*\.go$' && "$SOURCE_NAME" != *_test.go ]] || die '源码必须是普通 .go 文件名，不能是测试文件。'
}
# 创建独立新工程，先解析依赖再执行可选运行，失败时保留诊断现场。
create_go_project() {
  mkdir -p "$PROJECT_PARENT" || die "无法创建父目录：$PROJECT_PARENT"
  mkdir "$PROJECT_DIR" || die "工程目录创建失败：$PROJECT_DIR"
  cd "$PROJECT_DIR" || die '进入工程目录失败。'
  run_command go mod init "$MODULE_NAME" || die 'go mod init 失败。'
  cat > "$SOURCE_NAME" <<'GO'
package main

import "github.com/gin-gonic/gin"

func main() {
    router := gin.Default()
    router.GET("/ping", func(context *gin.Context) {
        context.JSON(200, gin.H{"message": "pong"})
    })
    if err := router.Run("127.0.0.1:8080"); err != nil {
        panic(err)
    }
}
GO
  run_command gofmt -w "$SOURCE_NAME" || die 'gofmt 失败。'
  { printf '# Go 环境\n\n```text\n'; go version; go env GOPATH GOMOD GOPROXY; printf '```\n'; } | sanitize_output > localGoEnvInfo.md
  log "✔ 已生成：$PROJECT_DIR"
  if ask_any_to_run '下载 Gin 依赖并执行 go mod tidy / go test'; then
    show_source 下载 Gin "Go module 当前 GOPROXY=$(go env GOPROXY)；github.com/gin-gonic/gin" "$PROJECT_DIR"
    run_command go mod tidy || die '依赖解析失败；工程文件已保留。'
    run_command go test ./... || die '工程校验失败；文件已保留。'
    if ask_any_to_run '前台运行示例（127.0.0.1:8080，Ctrl+C 停止）'; then
      run_command go run . || die '示例运行结束或启动失败，请检查端口及日志。'
    fi
  else
    log 'ℹ 工程骨架已生成；首次运行前需在工程中执行 go mod tidy。'
  fi
  if command -v code >/dev/null 2>&1 && ask_any_to_run '使用当前 VS Code 打开工程'; then
    run_command code "$PROJECT_DIR" || die '编辑器打开失败，工程已保留。'
  fi
  log "✔ 工程流程结束；日志：$LOG_FILE"
}
# 编排自述、初始化和独立业务步骤。
main() {
  show_script_intro_and_wait # 先展示用途与影响，确认前不写入。
  initialize_script_runtime # 确认后初始化选项与日志。
  prepare_go_environment # 在生成前验证 Homebrew、Go 及可选安装升级。
  collect_go_project # 验证父目录、名称与 module 参数，禁止覆盖已有工程。
  create_go_project # 生成模板并按选择下载依赖、校验和前台运行。
}

main "$@"

#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】JobsSql.sh
# - 核心用途：安装或升级 Homebrew MySQL，按需启动和交互登录。
# - 影响范围：Homebrew、所选 MySQL 公式及服务；保留已有数据库与认证配置。
# - 运行提示：先阅读内置自述并回车；普通动作回车跳过，危险动作精确输入 YES。
# shell: zsh
# 打印固定内置自述，确认前只做终端展示。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】JobsSql.sh'
  print -r -- '核心用途：安装或升级 Homebrew MySQL，按需启动和交互登录。'
  print -r -- '影响范围：Homebrew、所选 MySQL 公式及服务；保留已有数据库与认证配置。'
  print -r -- '运行策略：普通安装/升级回车跳过；危险动作必须精确输入 YES；Ctrl+C 取消。'
  print -r -- '日志位置：系统临时目录中的 【MacOS】JobsSql.log（阅读确认后才创建）。'
  print -r -- '============================================================================'
  [[ -t 0 ]] || { print -u2 -r -- '当前没有可交互输入，请在终端中重新运行。'; exit 1; }
  local answer=""
  print -n -r -- '已了解用途与影响，按回车继续；Ctrl+C 取消：'
  IFS= read -r answer || exit 1
}
# 过滤颜色与常见凭据，仅处理展示副本。
sanitize_stream() {
  /usr/bin/perl -pe 's/\e\[[0-?]*[ -\/]*[@-~]//g; s{(https?://)[^\s/@]+@}{${1}[REDACTED]\@}g; s{(https?://[^\s?#]+)[?#][^\s]*}{${1}?[REDACTED]}g; s{((?:password|passwd|token|secret|authorization)\s*[=:]\s*)[^\s,;]+}{${1}[REDACTED]}ig'
}
# 同步终端和纯文本日志，自述确认前不创建文件。
log() {
  local message="$*" clean
  clean="$(print -r -- "$message" | sanitize_stream)"
  print -r -- "$clean"
  [[ -z "${LOG_FILE:-}" ]] || print -r -- "$clean" >> "$LOG_FILE"
}
# 输出来源和实际目标，地址只在展示时脱敏。
source_log() {
  log "━━━━━━━━━━ 来源 ━━━━━━━━━━"
  log "对象：$1"
  log "来源地址：$2"
  log "目标位置：$3"
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
# 在包管理器解析最终下载地址前显示有效来源配置。
show_homebrew_source() {
  local brew_config
  brew_config="$("$JOBS_HOMEBREW_BIN" config)" || fail '无法读取 Homebrew 来源配置。'
  source_log "$1" 'Homebrew 当前生效软件源；最终包下载地址待 brew 解析' "$2"
  log "Formula API：${HOMEBREW_API_DOMAIN:-https://formulae.brew.sh/api}"
  log "Bottle 域名：${HOMEBREW_BOTTLE_DOMAIN:-https://ghcr.io/v2/homebrew/core}"
  if [[ -n "${HOMEBREW_ARTIFACT_DOMAIN:-}" ]]; then
    log "Artifact 覆盖域名：$HOMEBREW_ARTIFACT_DOMAIN"
  fi
  log '以下为 brew config 报告的来源覆盖项（若无输出则未报告覆盖项）：'
  print -r -- "$brew_config" | awk '/^HOMEBREW_.*(DOMAIN|REMOTE):/ {print}' | sanitize_stream | tee -a "$LOG_FILE"
}
# 保留外部命令退出码，同时过滤日志里的颜色和凭据。
run_logged() {
  "$@" 2>&1 | sanitize_stream | tee -a "$LOG_FILE"
  local -a results=("${pipestatus[@]}")
  local result
  for result in "${results[@]}"; do
    (( result == 0 )) || return "$result"
  done
  return 0
}
# 报错后停止下游操作，退出时由清理函数恢复未完成事务。
fail() {
  log "✖ $*"
  exit 1
}
# 普通动作回车跳过，输入流结束立即停止整个流程。
ask_any_to_run() {
  local answer=""
  print -n -r -- "$1（直接回车跳过；输入任意字符后回车执行）："
  IFS= read -r answer || { log "⚠ 输入已结束，停止。"; exit 1; }
  [[ -n "$answer" ]]
}
# 危险动作只接受精确大写 YES，取消不落入后续操作。
confirm_yes() {
  local answer=""
  log "⚠ $1"
  print -n -r -- '仅输入大写 YES 后回车执行；其它输入取消：'
  IFS= read -r answer || { log "⚠ 输入已结束，停止。"; exit 1; }
  [[ "$answer" == YES ]]
}
# 自述确认后才设置路径、日志、运行选项和异常清理。
initialize_script_runtime() {
  setopt NO_NOMATCH TYPESET_SILENT PIPE_FAIL
  umask 077
  SCRIPT_DIR="${${(%):-%x}:A:h}"
  SCRIPT_PATH="${${(%):-%x}:A}"
  SCRIPT_BASENAME="${SCRIPT_PATH:t:r}"
  LOG_FILE="${TMPDIR:-/tmp}/${SCRIPT_BASENAME}.log"
  if [[ -L "$LOG_FILE" || ( -e "$LOG_FILE" && ( ! -f "$LOG_FILE" || ! -O "$LOG_FILE" ) ) ]]; then
    print -u2 -r -- "日志目标不是当前用户拥有的普通文件，停止：$LOG_FILE"
    exit 1
  fi
  : > "$LOG_FILE" || exit 1
  chmod 600 "$LOG_FILE" || exit 1
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/jobs-mysql.XXXXXX")" || fail '不能创建临时工作目录。'
  trap 'cleanup_runtime' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  [[ "$(/usr/bin/uname -s)" == Darwin ]] || fail '仅支持 macOS。'
  export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1
  log "ℹ 日志：$LOG_FILE"
}
# 退出时清理临时文件，并按需要恢复配置或数据库事务。
cleanup_runtime() {
  local exit_code=$?
  trap - EXIT INT TERM
  if [[ "${TRANSACTION_ACTIVE:-0}" == 1 ]]; then
    rollback_transaction || exit_code=1
  fi
  [[ -z "${WORK_DIR:-}" || ! -d "$WORK_DIR" ]] || rm -r -- "$WORK_DIR"
  return "$exit_code"
}
# 非事务入口复用空恢复钩子，独立脚本按业务覆盖。
rollback_transaction() {
  return 0
}
# 仅复用健康 Homebrew，配置、重置和卸载不安装管理器。
prepare_existing_homebrew() {
  JOBS_HOMEBREW_BIN="$(jobs_brew_find)" || fail '未找到健康 Homebrew；请先用 JobsSql 安装入口准备环境。'
  jobs_brew_activate || fail 'Homebrew 激活或命令层复检失败。'
  log "ℹ Homebrew：$JOBS_HOMEBREW_BIN；真实前缀：$JOBS_HOMEBREW_PREFIX"
}
# 识别 mysql 或 mysql@版本；多版本环境必须明确选择。
select_mysql_formula() {
  local installed line answer=""
  local -a formulas=()
  installed="$("$JOBS_HOMEBREW_BIN" list --formula)" || fail '无法读取已安装公式。'
  for line in "${(@f)installed}"; do
    [[ "$line" == mysql || "$line" == mysql@[0-9]* ]] && formulas+=("$line")
  done
  if (( ${#formulas} == 0 )); then
    log 'ℹ 未安装 MySQL 公式。'
    return 1
  fi
  if (( ${#formulas} == 1 )); then
    MYSQL_FORMULA="$formulas[1]"
  else
    log "ℹ 已安装版本：${(j:, :)formulas}"
    print -n -r -- '输入本次操作的完整公式名称（回车取消）：'
    IFS= read -r answer || fail '输入已结束。'
    [[ -n "$answer" ]] || exit 0
    (( ${formulas[(Ie)$answer]} > 0 )) || fail '公式不在已安装清单中。'
    MYSQL_FORMULA="$answer"
  fi
  MYSQL_PREFIX="$("$JOBS_HOMEBREW_BIN" --prefix "$MYSQL_FORMULA")" || fail '无法解析 MySQL 安装前缀。'
  [[ "$MYSQL_PREFIX" == /* && -d "$MYSQL_PREFIX" ]] || fail 'MySQL 安装前缀无效。'
  MYSQLD="$MYSQL_PREFIX/bin/mysqld"
  MYSQL_CLIENT="$MYSQL_PREFIX/bin/mysql"
  [[ -x "$MYSQLD" && -x "$MYSQL_CLIENT" ]] || fail 'MySQL 可执行文件不完整。'
  "$MYSQLD" --version >/dev/null 2>&1 && "$MYSQL_CLIENT" --version >/dev/null 2>&1 || fail 'MySQL 命令健康检查失败。'
  DATA_DIR="$JOBS_HOMEBREW_PREFIX/var/mysql"
  CONFIG_FILE="$JOBS_HOMEBREW_PREFIX/etc/my.cnf"
  log "ℹ 公式：$MYSQL_FORMULA；程序：$MYSQL_PREFIX"
  log "ℹ 默认数据目录：$DATA_DIR；配置：$CONFIG_FILE"
}
# 读取实际服务器参数；自定义数据目录先停止，避免误处理其它实例。
inspect_mysql_defaults() {
  local defaults actual_data grants
  defaults="$("$MYSQLD" --verbose --help 2>"$WORK_DIR/defaults-error")" || fail 'MySQL 当前配置无法解析，请先修复配置。'
  actual_data="$(print -r -- "$defaults" | awk '$1 == "datadir" {sub(/^[[:space:]]*datadir[[:space:]]+/, ""); sub(/[[:space:]]+$/, ""); print; exit}')"
  [[ -n "$actual_data" && "${actual_data:A}" == "${DATA_DIR:A}" ]] || fail "实际数据目录不是 Homebrew 默认目录，停止：$actual_data"
  grants="$(print -r -- "$defaults" | awk '$1 == "skip-grant-tables" {print $2; exit}')"
  [[ "$grants" == FALSE || "$grants" == OFF || "$grants" == 0 ]] || fail '当前配置启用了 skip-grant-tables 或无法确认认证状态，请先移除该配置。'
  MYSQL_SOCKET="$(print -r -- "$defaults" | awk '$1 == "socket" {sub(/^[[:space:]]*socket[[:space:]]+/, ""); sub(/[[:space:]]+$/, ""); print; exit}')"
  MYSQL_BIND="$(print -r -- "$defaults" | awk '$1 == "bind-address" {print $2; exit}')"
  MYSQLX_BIND="$(print -r -- "$defaults" | awk '$1 == "mysqlx-bind-address" {print $2; exit}')"
  [[ "$MYSQL_SOCKET" == /* ]] || fail '无法确认 MySQL Unix socket 路径。'
}
# 确认没有 mysqld / mysqld_safe；查询失败不能作为停止依据。
mysql_processes_stopped() {
  local result=0
  pgrep -x 'mysqld|mysqld_safe' >/dev/null 2>&1 || result=$?
  case "$result" in
    0) return 1 ;;
    1) return 0 ;;
    *) fail "进程状态检查失败，退出码：$result" ;;
  esac
}
# 停止所选服务，并在任何 MySQL 后台进程仍运行时阻止目录操作。
stop_mysql_and_verify() {
  run_logged "$JOBS_HOMEBREW_BIN" services stop "$MYSQL_FORMULA" || fail "停止 $MYSQL_FORMULA 服务失败。"
  local attempt
  for attempt in {1..10}; do
    mysql_processes_stopped && return 0
    sleep 1
  done
  fail '仍有 MySQL 后台进程；请人工确认并停止后重试，尚未移动或删除数据目录。'
}
# 记录操作之前的服务状态，恢复时只启动原先运行的服务。
remember_service_state() {
  local services
  services="$("$JOBS_HOMEBREW_BIN" services list)" || fail '无法读取服务状态。'
  SERVICE_WAS_STARTED=0
  print -r -- "$services" | awk -v formula="$MYSQL_FORMULA" '$1 == formula && $2 == "started" {found=1} END {exit !found}' && SERVICE_WAS_STARTED=1
  return 0
}
# 等待有界的本地连接，验证时不读取用户密码配置。
verify_empty_root() {
  local attempt result
  for attempt in {1..15}; do
    if result="$(env -u MYSQL_PWD "$MYSQL_CLIENT" --no-defaults --no-login-paths --protocol=socket --socket="$MYSQL_SOCKET" --user=root --skip-password --connect-timeout=2 --batch --skip-column-names --execute='SELECT @@datadir, CURRENT_USER()' 2>/dev/null)"; then
      [[ "$result" == *$'\troot@localhost' && "${${result%%$'\t'*}:A}" == "${DATA_DIR:A}" ]] || return 1
      return 0
    fi
    sleep 1
  done
  return 1
}
# >>> Jobs Homebrew install choice >>>
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
  source_log "Homebrew 官方安装器" https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh "$installer"
  if curl -fsSL --connect-timeout 10 --max-time 120 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"; then
    run_logged /bin/bash "$installer" || installer_result=$?
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
  source_log "Homebrew 稳定版本元数据" https://api.github.com/repos/Homebrew/brew/releases/latest "$stage/release.json"
  if ! curl -fsSL --connect-timeout 10 --max-time 60 https://api.github.com/repos/Homebrew/brew/releases/latest -o "$stage/release.json"; then
    rm -r -- "$stage"
    jobs_brew_note "获取官方稳定版本失败，停止安装。"
    return 1
  fi
  release_tag="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "$stage/release.json" | head -n 1)"
  source_log "Homebrew 用户目录安装（GitHub 官方仓库；版本待解析）" https://github.com/Homebrew/brew.git "$prefix"
  if [[ ! "$release_tag" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] ||
     ! run_logged env GIT_TERMINAL_PROMPT=0 "$git_bin" -c http.lowSpeedLimit=1 -c http.lowSpeedTime=60 clone --depth 1 --branch "$release_tag" --single-branch https://github.com/Homebrew/brew.git "$stage/brew" ||
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
# 只更新本模块的 shellenv 配置块，并保留配置文件的符号链接和权限。
jobs_brew_save_shellenv() {
  local profile_file="$HOME/.zprofile" profile_stage shellenv_line current_shell="${SHELL:-/bin/zsh}"
  [[ "${current_shell##*/}" != bash ]] || profile_file="$HOME/.bash_profile"
  shellenv_line='eval "$('"${(q)JOBS_HOMEBREW_BIN}"' shellenv)"'
  profile_stage="$(mktemp "${TMPDIR:-/tmp}/jobs-homebrew-profile.XXXXXX")" || return 1
  if [[ -e "$profile_file" || -L "$profile_file" ]]; then
    awk '
      $0 == "# >>> Jobs Homebrew shellenv >>>" { inside = 1; block = $0 ORS; next }
      inside {
        block = block $0 ORS
        if ($0 == "# <<< Jobs Homebrew shellenv <<<") { inside = 0; block = "" }
        next
      }
      { print }
      END { if (inside) printf "%s", block }
    ' "$profile_file" > "$profile_stage" || { rm -- "$profile_stage"; return 1; }
  fi
  {
    print -r -- '# >>> Jobs Homebrew shellenv >>>'
    print -rl -- "$shellenv_line" '# <<< Jobs Homebrew shellenv <<<'
  } >> "$profile_stage"
  if ! cmp -s "$profile_stage" "$profile_file"; then
    cat "$profile_stage" > "$profile_file" || { rm -- "$profile_stage"; jobs_brew_note "无法写入用户配置：$profile_file"; return 1; }
  fi
  rm -- "$profile_stage"
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
    jobs_brew_save_shellenv || return 1
  fi
}
# 在原版安装位置复用或安装 Homebrew，安装失败必须终止外层业务。
jobs_brew_install_or_exit() {
  local installed=""
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    jobs_brew_note "演练：Homebrew 系统路径 $(jobs_brew_system_prefix)；用户路径 ${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}；未询问或执行安装。"
    return 0
  fi
  if ! JOBS_HOMEBREW_BIN="$(jobs_brew_find)"; then
    ask_any_to_run "安装缺失的 Homebrew" || { log "ℹ 未安装 Homebrew，停止后续安装。"; exit 0; }
    jobs_brew_choose_installation || exit 1
    case "$JOBS_HOMEBREW_INSTALL_MODE" in
      system) jobs_brew_install_system || exit 1 ;;
      user) jobs_brew_install_user || exit 1 ;;
      *) jobs_brew_note "安装路径选择无效，停止。"; exit 1 ;;
    esac
    installed=installed
  fi
  jobs_brew_activate "$installed" || exit 1
}
# <<< Jobs Homebrew install choice <<<
# 安装入口可以按用户确认修复缺失 Homebrew，健康安装继续询问更新。
prepare_install_homebrew() {
  jobs_brew_install_or_exit
  if ask_any_to_run '更新 Homebrew 自身与公式索引'; then
    show_homebrew_source 'Homebrew 更新' "$JOBS_HOMEBREW_PREFIX"
    run_logged "$JOBS_HOMEBREW_BIN" update || fail 'Homebrew 更新失败。'
    jobs_brew_activate || fail '更新后 Homebrew 复检失败。'
  fi
}
# 安装或升级所选 MySQL，保留数据且不改认证配置。
install_or_upgrade_mysql() {
  if select_mysql_formula; then
    if ask_any_to_run "升级 $MYSQL_FORMULA（请先自行完成数据库备份，跨主版本升级需核对兼容性）"; then
      show_homebrew_source "$MYSQL_FORMULA 升级" "$MYSQL_PREFIX"
      run_logged "$JOBS_HOMEBREW_BIN" upgrade "$MYSQL_FORMULA" || fail 'MySQL 升级失败。'
      select_mysql_formula || fail '升级后未找到 MySQL。'
    fi
  else
    ask_any_to_run '安装 Homebrew 当前 mysql 公式' || { log 'ℹ 已跳过 MySQL 安装。'; return 0; }
    show_homebrew_source 'mysql 安装' "$JOBS_HOMEBREW_PREFIX"
    run_logged "$JOBS_HOMEBREW_BIN" install mysql || fail 'MySQL 安装失败。'
    select_mysql_formula || fail '安装后未找到 MySQL。'
  fi
  run_logged "$JOBS_HOMEBREW_BIN" info "$MYSQL_FORMULA" || fail '读取 MySQL 安装信息失败。'
  if ask_any_to_run "启动或重启 $MYSQL_FORMULA 服务"; then
    inspect_mysql_defaults
    run_logged "$JOBS_HOMEBREW_BIN" services restart "$MYSQL_FORMULA" || fail 'MySQL 服务启动失败。'
  fi
  if ask_any_to_run '进入 MySQL root 交互客户端（密码由客户端在终端读取）'; then
    inspect_mysql_defaults
    env -u MYSQL_PWD "$MYSQL_CLIENT" --no-defaults --no-login-paths --protocol=socket --socket="$MYSQL_SOCKET" --user=root --password || fail 'MySQL 登录失败；脚本未修改密码。'
  fi
  log '✔ MySQL 安装入口执行完成；认证保持启用。'
}
# 编排自述、运行环境与本入口的业务流程。
main() {
  show_script_intro_and_wait # 先展示固定自述并等待用户确认，取消时不创建日志。
  initialize_script_runtime # 确认后初始化运行选项、私有临时目录和日志。
  prepare_install_homebrew # 在本脚本内验证并激活 Homebrew，失败时停止后续业务。
  install_or_upgrade_mysql # 执行本入口的 MySQL 操作，并保留失败退出状态。
}

main "$@"

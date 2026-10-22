#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh
# - 核心用途：编辑、验证并备份 Homebrew 的有效 my.cnf，按需重启。
# - 影响范围：Homebrew 前缀下 etc/my.cnf 及所选 MySQL 服务；失败时尝试恢复原配置。
# - 运行提示：先阅读内置自述并回车；普通动作回车跳过，危险动作精确输入 YES。
# shell: zsh
# 打印固定内置自述，确认前只做终端展示。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh'
  print -r -- '核心用途：编辑、验证并备份 Homebrew 的有效 my.cnf，按需重启。'
  print -r -- '影响范围：Homebrew 前缀下 etc/my.cnf 及所选 MySQL 服务；失败时尝试恢复原配置。'
  print -r -- '运行策略：普通安装/升级回车跳过；危险动作必须精确输入 YES；Ctrl+C 取消。'
  print -r -- '日志位置：系统临时目录中的 【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.log（阅读确认后才创建）。'
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
# 激活当前进程并验证 Ruby 命令层；只有新安装才持久化 shellenv。
jobs_brew_activate() {
  local brew_env
  brew_env="$("$JOBS_HOMEBREW_BIN" shellenv)" || return 1
  eval "$brew_env" || return 1
  typeset -g JOBS_HOMEBREW_PREFIX="$("$JOBS_HOMEBREW_BIN" --prefix)"
  export PATH="$JOBS_HOMEBREW_PREFIX/bin:$JOBS_HOMEBREW_PREFIX/sbin:$PATH"
  rehash
  HOMEBREW_NO_AUTO_UPDATE=1 "$JOBS_HOMEBREW_BIN" config >/dev/null || { jobs_brew_note "Homebrew 命令层复检失败，停止后续业务。"; return 1; }
}
# 配置事务失败时恢复原文件；不覆盖运行期间出现的并发修改。
rollback_transaction() {
  [[ "${TRANSACTION_ACTIVE:-0}" == 1 ]] || return 0
  if [[ "$CONFIG_EXISTED" == 1 ]] && cmp -s "$CONFIG_FILE" "$WORK_DIR/original.cnf"; then
    TRANSACTION_ACTIVE=0
    return 0
  fi
  if [[ "$CONFIG_EXISTED" != 1 && ! -e "$CONFIG_FILE" && ! -L "$CONFIG_FILE" ]]; then
    TRANSACTION_ACTIVE=0
    return 0
  fi
  if ! cmp -s "$CONFIG_FILE" "$WORK_DIR/applied.cnf"; then
    log "✖ 配置已被其它进程修改，未覆盖；原文件备份：${CONFIG_BACKUP:-无（原本不存在）}"
    return 1
  fi
  if [[ "$CONFIG_EXISTED" == 1 ]]; then
    cp -p -- "$CONFIG_BACKUP" "$CONFIG_FILE" || { log "✖ 恢复失败：$CONFIG_BACKUP → $CONFIG_FILE"; return 1; }
  else
    rm -- "$CONFIG_FILE" || return 1
  fi
  TRANSACTION_ACTIVE=0
  log '⚠ 已恢复原配置。'
  if [[ "${RESTART_ATTEMPTED:-0}" == 1 && "$SERVICE_WAS_STARTED" != 1 ]]; then
    run_logged "$JOBS_HOMEBREW_BIN" services stop "$MYSQL_FORMULA" || return 1
  fi
  if [[ "$SERVICE_WAS_STARTED" == 1 ]]; then
    run_logged "$JOBS_HOMEBREW_BIN" services restart "$MYSQL_FORMULA" || { log '✖ 原配置已恢复，但服务重启失败，请人工检查。'; return 1; }
  fi
}
# 在独立候选文件里编辑，校验、备份和危险确认后才写入真实配置。
edit_mysql_configuration() {
  select_mysql_formula || fail '配置入口要求已经安装 MySQL。'
  [[ ! -L "$CONFIG_FILE" && ( ! -e "$CONFIG_FILE" || -f "$CONFIG_FILE" ) ]] || fail '配置不是普通文件，停止。'
  [[ -w "${CONFIG_FILE:h}" ]] || fail 'Homebrew 配置目录不可写；请检查所有权，本脚本不使用 sudo 覆盖系统配置。'
  CONFIG_EXISTED=0
  if [[ -f "$CONFIG_FILE" ]]; then
    CONFIG_EXISTED=1
    cp -p -- "$CONFIG_FILE" "$WORK_DIR/original.cnf" || fail '读取原配置失败。'
    cp -p -- "$CONFIG_FILE" "$WORK_DIR/candidate.cnf" || fail '创建编辑副本失败。'
  else
    print -r -- $'[mysqld]\nbind-address=127.0.0.1\n# 可按需要添加：\n# gtid_mode=ON\n# log_replica_updates=ON\n# enforce_gtid_consistency=ON' > "$WORK_DIR/candidate.cnf" || fail '创建候选配置失败。'
  fi
  log "ℹ 编辑副本：$WORK_DIR/candidate.cnf；原配置尚未修改。"
  if command -v code >/dev/null 2>&1; then
    code --wait "$WORK_DIR/candidate.cnf" || fail '编辑器退出失败。'
  else
    /usr/bin/vi "$WORK_DIR/candidate.cnf" || fail '编辑器退出失败。'
  fi
  if grep -Eiq '^[[:space:]]*(loose[-_])?skip[-_]grant[-_]tables([[:space:]=]|$)' "$WORK_DIR/candidate.cnf"; then
    fail '候选配置包含 skip-grant-tables，禁止持久关闭认证。'
  fi
  run_logged "$MYSQLD" --defaults-file="$WORK_DIR/candidate.cnf" --validate-config || fail '候选配置校验失败，原配置未修改。'
  if [[ "$CONFIG_EXISTED" == 1 ]]; then
    cmp -s "$CONFIG_FILE" "$WORK_DIR/original.cnf" || fail '编辑期间原配置已变化，请重新运行并合并。'
    cmp -s "$CONFIG_FILE" "$WORK_DIR/candidate.cnf" && { log 'ℹ 配置未变化。'; return 0; }
  else
    [[ ! -e "$CONFIG_FILE" && ! -L "$CONFIG_FILE" ]] || fail '编辑期间出现新配置，请重新运行并合并。'
  fi
  confirm_yes "应用配置到 $CONFIG_FILE；可能改变数据库行为" || { log 'ℹ 已取消配置写入。'; return 0; }
  remember_service_state
  if [[ "$CONFIG_EXISTED" == 1 ]]; then
    CONFIG_BACKUP="$(mktemp "${CONFIG_FILE}.jobs-backup.XXXXXX")" || fail '创建配置备份失败。'
    cp -p -- "$CONFIG_FILE" "$CONFIG_BACKUP" || fail '保存原配置失败。'
    log "ℹ 原配置备份：$CONFIG_BACKUP"
  fi
  cp -p -- "$WORK_DIR/candidate.cnf" "$WORK_DIR/applied.cnf" || fail '保存预期配置失败。'
  local config_stage
  config_stage="$(mktemp "${CONFIG_FILE}.jobs-stage.XXXXXX")" || fail '创建配置暂存文件失败。'
  cp -p -- "$WORK_DIR/candidate.cnf" "$config_stage" || { rm -- "$config_stage"; fail '保存候选配置失败。'; }
  TRANSACTION_ACTIVE=1
  mv -f -- "$config_stage" "$CONFIG_FILE" || { rm -- "$config_stage"; fail '原子替换配置失败。'; }
  run_logged "$MYSQLD" --validate-config || fail '整体有效配置校验失败。'
  local effective grants
  effective="$("$MYSQLD" --verbose --help 2>/dev/null)" || fail '整体配置读取失败。'
  grants="$(print -r -- "$effective" | awk '$1 == "skip-grant-tables" {print $2; exit}')"
  [[ "$grants" == FALSE || "$grants" == OFF || "$grants" == 0 ]] || fail '整体配置关闭了认证，恢复原配置。'
  if ask_any_to_run "重启 $MYSQL_FORMULA 应用配置"; then
    RESTART_ATTEMPTED=1
    run_logged "$JOBS_HOMEBREW_BIN" services restart "$MYSQL_FORMULA" || fail '服务重启失败。'
    sleep 2
    local services
    services="$("$JOBS_HOMEBREW_BIN" services list)" || fail '无法复检服务状态。'
    print -r -- "$services" | awk -v formula="$MYSQL_FORMULA" '$1 == formula && $2 == "started" {found=1} END {exit !found}' || fail '服务没有进入 started 状态。'
  else
    log 'ℹ 配置已保存，尚未通过服务重启应用。'
  fi
  TRANSACTION_ACTIVE=0
  log "✔ 配置保存成功：$CONFIG_FILE"
}
# 编排自述、运行环境与本入口的业务流程。
main() {
  show_script_intro_and_wait # 先展示固定自述并等待用户确认，取消时不创建日志。
  initialize_script_runtime # 确认后初始化运行选项、私有临时目录和日志。
  prepare_existing_homebrew # 在本脚本内验证并激活 Homebrew，失败时停止后续业务。
  edit_mysql_configuration # 执行本入口的 MySQL 操作，并保留失败退出状态。
}

main "$@"

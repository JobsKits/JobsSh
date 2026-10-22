#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】向系统受保护区域文件末尾追加写入内容.sh
# - 核心用途：向指定普通文件追加一行文本，保留原始备份并检测并发变化。
# - 影响范围：输入 YES 后才写目标；必要时请求 sudo；备份保存在目标同目录，绝不关闭 SIP。
# - 运行提示：先展示内置自述，回车继续；Ctrl+C 或 EOF 停止，危险操作要求 YES。
# shell: zsh
SCRIPT_SOURCE="${(%):-%x}"
SCRIPT_PURPOSE='向指定普通文件追加一行文本，保留原始备份并检测并发变化。'
SCRIPT_IMPACT='输入 YES 后才写目标；必要时请求 sudo；备份保存在目标同目录，绝不关闭 SIP。'

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
# 收集唯一目标与待追加文本，禁止符号链接和多硬链接写入。
collect_append_target() {
  read_paths '拖入待追加的现有文件：'
  (( ${#PATH_INPUTS} == 1 )) || die '必须指定一个现有文件。'
  [[ ! -L "${PATH_INPUT_RAW[1]}" ]] || die '拒绝直接修改符号链接，请明确选择实际文件。'
  TARGET_FILE="${PATH_INPUTS[1]}"
  [[ -f "$TARGET_FILE" && ! -L "$TARGET_FILE" ]] || die '目标必须是普通文件。'
  [[ "$(stat -f %l "$TARGET_FILE")" == 1 ]] || die '目标存在多个硬链接，请先人工核对。'
  IFS= read -r 'APPEND_TEXT?输入待追加的一行内容（内容不写入日志）：' || die '输入结束，已停止。'
  [[ -n "$APPEND_TEXT" ]] || die '追加内容为空，已取消。'
  log "ℹ 目标：$TARGET_FILE"
  confirm_yes '备份原文件并追加上述内容' || { log 'ℹ 已取消，目标未改动。'; exit 0; }
}
# 失败或中断时仅清理本脚本持有的尚未发布临时文件。
cleanup_append_stage() {
  if [[ -n "${APPEND_STAGE:-}" ]]; then
    if (( ${#PRIVILEGE[@]} )); then
      sudo -n /bin/rm -f -- "$APPEND_STAGE" || print -u2 -r -- "⚠ 临时文件需人工清理：$APPEND_STAGE"
    else
      /bin/rm -f -- "$APPEND_STAGE"
    fi
  fi
}
# 在同目录构造副本并原子替换，失败时保留备份与具体恢复路径。
append_with_backup() {
  PRIVILEGE=()
  if [[ ! -w "${TARGET_FILE:h}" || ! -r "$TARGET_FILE" || "$(stat -f %u "$TARGET_FILE")" != "$EUID" ]]; then
    command -v sudo >/dev/null 2>&1 || die '需要管理员权限但 sudo 不可用。'
    sudo -v || die '管理员授权失败。'
    PRIVILEGE=(sudo)
  fi
  APPEND_BACKUP="$("${PRIVILEGE[@]}" /usr/bin/mktemp "${TARGET_FILE}.jobs-backup.XXXXXX")" || die '无法创建备份；目标可能受 SIP 或权限保护。'
  "${PRIVILEGE[@]}" /bin/cp -p "$TARGET_FILE" "$APPEND_BACKUP" || die "备份失败：$APPEND_BACKUP"
  log "✔ 原文件备份：$APPEND_BACKUP"
  APPEND_STAGE="$("${PRIVILEGE[@]}" /usr/bin/mktemp "${TARGET_FILE:h}/.jobs-append.XXXXXX")" || die '无法创建同目录临时文件。'
  trap cleanup_append_stage EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
  "${PRIVILEGE[@]}" /bin/cp -p "$APPEND_BACKUP" "$APPEND_STAGE" || die '无法准备待写副本。'
  if [[ -s "$APPEND_STAGE" ]]; then
    if [[ "$("${PRIVILEGE[@]}" /usr/bin/tail -c 1 "$APPEND_STAGE" | /usr/bin/od -An -tu1 | tr -d ' ')" != 10 ]]; then
      printf '\n' | "${PRIVILEGE[@]}" /usr/bin/tee -a "$APPEND_STAGE" >/dev/null || die '补齐换行失败。'
    fi
  fi
  printf '%s\n' "$APPEND_TEXT" | "${PRIVILEGE[@]}" /usr/bin/tee -a "$APPEND_STAGE" >/dev/null || die '追加副本失败。'
  "${PRIVILEGE[@]}" /usr/bin/cmp -s "$TARGET_FILE" "$APPEND_BACKUP" || die '原文件已并发变化，保留新状态，未写回。'
  local expected actual
  expected="$("${PRIVILEGE[@]}" /bin/cat "$APPEND_STAGE" | /usr/bin/shasum -a 256)" || die '待写副本校验失败。'
  expected="${expected%% *}"
  "${PRIVILEGE[@]}" /usr/bin/perl -e 'rename($ARGV[0], $ARGV[1]) or die "$!\n"' "$APPEND_STAGE" "$TARGET_FILE" || die "写回失败，原始备份：$APPEND_BACKUP"
  APPEND_STAGE=''
  actual="$("${PRIVILEGE[@]}" /bin/cat "$TARGET_FILE" | /usr/bin/shasum -a 256)" || die '写后读取校验失败。'
  [[ "${actual%% *}" == "$expected" ]] || die "写后验证失败；保留备份：$APPEND_BACKUP"
  log "✔ 已追加并验证：$TARGET_FILE"
  log "ℹ 恢复前先核对后续改动，再将备份复制回目标；备份：$APPEND_BACKUP"
}
# 编排自述、初始化和独立业务步骤。
main() {
  show_script_intro_and_wait # 先展示用途与影响，确认前不写入。
  initialize_script_runtime # 确认后初始化选项与日志。
  collect_append_target # 验证唯一目标，读取内容并要求精确 YES。
  append_with_backup # 备份原文，检测并发变化后写回并验证。
}

main "$@"

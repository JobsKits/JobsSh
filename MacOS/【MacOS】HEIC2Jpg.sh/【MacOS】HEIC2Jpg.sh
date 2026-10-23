#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】HEIC2Jpg.sh
# - 核心用途：将一个或多个目录中的 HEIC 转换为 JPEG，保留原图及已存在的 JPEG。
# - 影响范围：仅在选择的输出目录创建新 JPEG；单层处理，不覆盖任何已有目标。
# - 运行提示：先展示内置自述，回车继续；Ctrl+C 或 EOF 停止，危险操作要求 YES。
# shell: zsh
SCRIPT_SOURCE="${(%):-%x}"
SCRIPT_PURPOSE='将一个或多个目录中的 HEIC 转换为 JPEG，保留原图及已存在的 JPEG。'
SCRIPT_IMPACT='仅在选择的输出目录创建新 JPEG；单层处理，不覆盖任何已有目标。'

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
# 收集输入目录与输出位置，兼容多个 Finder 拖入路径。
collect_conversion_paths() {
  read_paths '拖入一个或多个 HEIC 输入目录：'
  (( ${#PATH_INPUTS} > 0 )) || die '未指定输入目录。'
  INPUT_DIRS=("${PATH_INPUTS[@]}")
  local directory
  for directory in "${INPUT_DIRS[@]}"; do
    [[ -d "$directory" ]] || die "输入目录不存在：$directory"
  done
  read_paths '拖入输出目录（回车使用首个输入目录下的 JPEG）：'
  (( ${#PATH_INPUTS} <= 1 )) || die '只能指定一个输出目录。'
  OUTPUT_DIR="${PATH_INPUTS[1]:-${INPUT_DIRS[1]}/JPEG}"
  [[ ! -L "$OUTPUT_DIR" && ( ! -e "$OUTPUT_DIR" || -d "$OUTPUT_DIR" ) ]] || die "输出目标不是普通目录：$OUTPUT_DIR"
}
# 使用系统图片工具转换，并仅在转换成功后发布完整输出。
convert_heic_images() {
  command -v sips >/dev/null 2>&1 || die '未找到系统 sips。'
  mkdir -p "$OUTPUT_DIR" || die "无法创建输出目录：$OUTPUT_DIR"
  local directory file target stage manifest count=0 done_count=0 skipped=0 failures=0
  manifest="$(mktemp "${TMPDIR:-/tmp}/jobs-heic-files.XXXXXX")"
  for directory in "${INPUT_DIRS[@]}"; do
    if ! find "$directory" -maxdepth 1 -type f -iname '*.heic' -print0 > "$manifest"; then
      rm -- "$manifest"
      die "读取目录失败：$directory"
    fi
    while IFS= read -r -d '' file; do
      (( count += 1 ))
      target="$OUTPUT_DIR/${file:t:r}.jpg"
      if [[ -e "$target" || -L "$target" ]]; then
        log "⚠ 已存在，保留并跳过：$target"
        (( skipped += 1 ))
        continue
      fi
      stage="$(mktemp "$OUTPUT_DIR/.jobs-heic.XXXXXX")"
      if run_command sips -s format jpeg "$file" --out "$stage" && [[ -s "$stage" ]] && /usr/bin/perl -e 'link($ARGV[0], $ARGV[1]) or die "$!\n"' "$stage" "$target"; then
        log "✔ 已转换：$file → $target"
        (( done_count += 1 ))
      else
        log "✖ 转换失败或目标被并发创建：$file"
        (( failures += 1 ))
      fi
      rm -- "$stage"
    done < "$manifest"
  done
  rm -- "$manifest"
  log "ℹ 总数 $count，成功 $done_count，已存在跳过 $skipped，失败 $failures；日志：$LOG_FILE"
  (( count > 0 )) || log 'ℹ 输入目录没有 HEIC 文件。'
  (( failures == 0 )) || exit 1
}
# 编排自述、初始化和独立业务步骤。
main() {
  show_script_intro_and_wait # 先展示用途与影响，确认前不写入。
  initialize_script_runtime # 确认后初始化选项与日志。
  collect_conversion_paths # 校验所有输入目录并选择输出位置。
  convert_heic_images # 保护原图及已有目标，汇总实际转换结果。
}

main "$@"

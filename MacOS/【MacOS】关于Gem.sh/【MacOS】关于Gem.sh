#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】关于Gem.sh
# - 核心用途：查看 RubyGems 软件源，可选修改用户源、更新与清理。
# - 影响范围：系统 Ruby 只读；软件源配置和删除旧 Gem 须输入 YES；不使用 sudo。
# - 运行提示：先展示自述，回车继续；普通写操作回车跳过，Ctrl+C 或 EOF 取消。
# shell: zsh
SCRIPT_SOURCE="${(%):-%x}"
# 在任何写入前说明用途与风险，并阻止无交互运行。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】关于Gem.sh'
  print -r -- '核心用途：查看 RubyGems 软件源，可选修改用户源、更新与清理。'
  print -r -- '影响范围：系统 Ruby 只读；软件源配置和删除旧 Gem 须输入 YES；不使用 sudo。'
  print -r -- '运行策略：安装/升级直接回车跳过，输入任意字符执行；持久配置或清理需 YES。'
  print -r -- '取消方式：Ctrl+C 或输入结束立即停止；确认前不会写日志或执行安装。'
  print -r -- "脚本位置：${SCRIPT_SOURCE:A}"
  print -r -- "日志位置：${TMPDIR:-/tmp}/${${${SCRIPT_SOURCE:A}:t}%.*}.log"
  print -r -- '============================================================================'
  [[ -t 0 ]] || { print -u2 -r -- '✖ 没有可交互输入，请在终端中使用 zsh 运行。'; exit 1; }
  read -r '?👉 已了解用途与影响，按回车继续；Ctrl+C 取消：' _ || exit 1
}
# 剥离展示控制码、URL 凭据与查询参数，业务地址保持原样。
sanitize_stream() {
  /usr/bin/perl -pe 's/\e\[[0-?]*[ -\/]*[@-~]//g; s{(https?://)[^/\s\@]+\@}{${1}[REDACTED]\@}g; s{(https?://[^\s?#]+)[?#][^\s]*}{$1?[REDACTED]}g'
}
# 将相同的纯文本消息显示到终端并保存到运行日志。
log() {
  local message
  message="$(print -r -- "$*" | sanitize_stream)"
  if [[ -n "${LOG_FILE:-}" ]]; then
    print -r -- "$message" >> "$LOG_FILE" || exit 1
  fi
  if [[ -t 1 && -n "${TERM:-}" && "$TERM" != dumb && -z "${NO_COLOR+x}" && "${PLAIN_OUTPUT:-0}" != 1 ]]; then
    printf '\033[1;34m%s\033[0m\n' "$message"
  else
    print -r -- "$message"
  fi
}
# 报告具体失败并阻止后续业务继续执行。
fail() {
  log "✖ $*"
  exit 1
}
# 执行外部命令，保留输出与真实失败状态。
run_logged() {
  local result
  local -a results
  "$@" 2>&1 | sanitize_stream | tee -a "$LOG_FILE"
  results=("${pipestatus[@]}")
  for result in "${results[@]}"; do
    (( result == 0 )) || return "$result"
  done
  return 0
}
# 对普通安装、升级动作采用回车跳过，EOF 则终止整个任务。
ask_any_to_run() {
  local answer=""
  print -n -r -- "$1（直接回车跳过；输入任意字符后回车执行）："
  IFS= read -r answer || fail '输入结束，已停止后续操作。'
  [[ -n "$answer" ]]
}
# 对持久配置、系统目录和清理动作使用精确 YES 门禁。
confirm_yes() {
  local answer=""
  log "⚠ $1"
  print -n -r -- '输入精确大写 YES 执行；其它输入取消：'
  IFS= read -r answer || fail '输入结束，已停止后续操作。'
  [[ "$answer" == YES ]]
}
# 输出已知的软件源、目标与解析边界，不额外联网探测。
show_source() {
  log "━━━━━━━━━━ 来源｜$1 ━━━━━━━━━━"
  log "📦 对象：$2"
  log "📥 来源地址：$3"
  log "📂 目标位置：$4"
  log '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
}
# 标明 Homebrew 本次使用的元数据和包下载配置。
show_brew_source() {
  show_source "$1" "$2" "${HOMEBREW_API_DOMAIN:-https://formulae.brew.sh/api}；包下载地址由 Homebrew 解析" "$3"
  log "软件仓库：${HOMEBREW_CORE_GIT_REMOTE:-https://github.com/Homebrew/homebrew-core}"
  log "Bottle 软件源：${HOMEBREW_BOTTLE_DOMAIN:-https://ghcr.io/v2/homebrew/core}"
  [[ -z "${HOMEBREW_ARTIFACT_DOMAIN:-}" ]] || log "下载覆盖源：$HOMEBREW_ARTIFACT_DOMAIN"
}
# 在首屏确认之后初始化选项、路径和日志。
initialize_script_runtime() {
  setopt NO_NOMATCH TYPESET_SILENT PIPE_FAIL
  [[ "$(uname -s)" == Darwin ]] || fail '当前脚本仅支持 macOS。'
  SCRIPT_PATH="${SCRIPT_SOURCE:A}"
  SCRIPT_DIR="${SCRIPT_PATH:h}"
  SCRIPT_BASENAME="${${SCRIPT_PATH:t}%.*}"
  LOG_FILE="${TMPDIR:-/tmp}/${SCRIPT_BASENAME}.log"
  [[ ! -L "$LOG_FILE" && ( ! -e "$LOG_FILE" || ( -f "$LOG_FILE" && -O "$LOG_FILE" ) ) ]] || fail "日志目标不是普通文件：$LOG_FILE"
  umask 077
  : > "$LOG_FILE" || fail "无法初始化日志：$LOG_FILE"
  chmod 600 "$LOG_FILE" || fail "无法保护日志权限：$LOG_FILE"
  export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_COLOR=0 FORCE_COLOR=0 CLICOLOR=0
  log "ℹ 当前脚本：$SCRIPT_PATH；日志：$LOG_FILE"
}
# 仅替换成对受控块，写前留精确备份并检查并发修改。
write_managed_block() {
  local target="$1" name="$2" content="$3" stage backup="" exists=0
  local begin="# >>> Jobs $name >>>" end="# <<< Jobs $name <<<"
  [[ ! -L "$target" && ( ! -e "$target" || -f "$target" ) ]] || fail "拒绝覆盖符号链接或特殊配置文件：$target"
  stage="$(mktemp "${target}.jobs-stage.XXXXXX")" || fail "无法创建配置暂存：$target"
  if [[ -e "$target" ]]; then
    exists=1
    backup="$(mktemp "${target}.jobs-backup.XXXXXX")" || fail "无法备份：$target"
    cp -p "$target" "$backup" && chmod 600 "$backup" || fail "备份失败：$target"
    if ! awk -v b="$begin" -v e="$end" '
      $0 == b { if (inside) exit 2; inside=1; next }
      $0 == e { if (!inside) exit 2; inside=0; next }
      !inside { print }
      END { if (inside) exit 2 }
    ' "$backup" > "$stage"; then
      rm -- "$stage"
      fail "受控块边界异常，保留原配置与备份：$backup"
    fi
  fi
  print -r -- "$begin" >> "$stage"
  print -r -- "$content" >> "$stage"
  print -r -- "$end" >> "$stage"
  /bin/zsh -n "$stage" || fail "配置语法检查失败，保留暂存：$stage"
  if (( exists )); then
    cmp -s "$target" "$backup" || fail "配置已被其它进程修改，未覆盖；备份：$backup"
    if cmp -s "$target" "$stage"; then
      rm -- "$stage" "$backup"
      log "ℹ 受控配置已经一致：$target"
      return 0
    fi
  else
    [[ ! -e "$target" && ! -L "$target" ]] || fail "配置目标已出现，未覆盖：$target"
  fi
  cat "$stage" > "$target" || fail "配置写入失败；备份：${backup:-原文件不存在}"
  rm -- "$stage"
  log "✔ 已写入受控块：$target；恢复备份：${backup:-原文件不存在，恢复时仅移除本受控块}"
}
# 输出当前运行结束位置，便于离线排查。
report_completion() {
  log "✔ 所选步骤已处理；日志：$LOG_FILE"
}
# 验证 Ruby 与 Gem 实际运行环境，记录系统 Ruby 的保护边界。
inspect_gem_environment() {
  RUBY_BIN="$(command -v ruby 2>/dev/null)"
  GEM_BIN="$(command -v gem 2>/dev/null)"
  [[ -n "$RUBY_BIN" && -n "$GEM_BIN" ]] || fail '缺少 Ruby / Gem，请先使用升级 Ruby 脚本准备用户工具链。'
  "$RUBY_BIN" --version >/dev/null 2>&1 && "$GEM_BIN" --version >/dev/null 2>&1 || fail 'Ruby / Gem 健康检查失败。'
  GEM_RUBY="$("$GEM_BIN" environment | awk -F ": " '/RUBY EXECUTABLE:/ { print $2; exit }')" || fail '无法解析 Gem 的 Ruby 运行环境。'
  [[ -x "$GEM_RUBY" ]] && "$GEM_RUBY" --version >/dev/null 2>&1 || fail 'Gem 的 Ruby 运行时不可用。'
  RUBY_BIN="$GEM_RUBY"
  GEM_HOME_RESOLVED="$("$GEM_BIN" environment home)" || fail '无法读取 Gem 安装目录。'
  log "ℹ Ruby：$RUBY_BIN；Gem：$GEM_BIN；Gem Home：$GEM_HOME_RESOLVED"
  run_logged "$GEM_BIN" sources --list || fail '无法读取 Gem 软件源。'
}
# 将软件源写入独立暂存配置，验证后再检查并发变化并替换用户文件。
configure_gem_source() {
  local choice="" source config="$HOME/.gemrc" backup="" stage exists=0
  log 'ℹ 软件源选择：1 官方 https://rubygems.org/；2 Ruby China https://gems.ruby-china.com/；直接回车保留。'
  print -n -r -- '➤ 选择：'
  IFS= read -r choice || fail '输入结束，未修改 Gem 软件源。'
  case "$choice" in
    '') return 0 ;;
    1) source=https://rubygems.org/ ;;
    2) source=https://gems.ruby-china.com/ ;;
    *) fail '无效软件源选择，未修改配置。' ;;
  esac
  confirm_yes "将用户级 Gem 软件源替换为 $source？先备份 .gemrc，原有其它配置保留。" || return 0
  [[ ! -L "$config" && ( ! -e "$config" || -f "$config" ) ]] || fail "拒绝修改符号链接或特殊配置：$config"
  stage="$(mktemp "${config}.jobs-stage.XXXXXX")" || fail '无法创建 .gemrc 暂存。'
  if [[ -f "$config" ]]; then
    exists=1
    backup="$(mktemp "${config}.jobs-backup.XXXXXX")" || fail '无法备份 .gemrc。'
    cp -p "$config" "$backup" && chmod 600 "$backup" || fail '.gemrc 备份失败。'
    cat "$backup" > "$stage" || fail '.gemrc 暂存失败。'
  fi
  show_source '配置软件源' RubyGems "$source" "$config"
  if ! run_logged "$RUBY_BIN" -rrubygems -rpsych -e '
    file, source = ARGV
    document = Psych.parse_file(file)
    abort "Gem 配置必须是 YAML 映射" if document && document.root && !document.root.is_a?(Psych::Nodes::Mapping)
    config = Gem::ConfigFile.new(["--config-file", file])
    Gem.configuration = config
    Gem.sources = [source]
    config[:sources] = [source]
    config.sources = [source]
    config.write
    check = Gem::ConfigFile.new(["--config-file", file])
    abort "Gem 软件源落盘复检失败" unless check.sources == [source]
  ' "$stage" "$source"; then
    fail "Gem 软件源暂存失败，原件未改；备份：${backup:-原文件不存在}；暂存：$stage"
  fi
  if (( exists )); then
    cmp -s "$config" "$backup" || fail "Gem 配置发生并发变化，未覆盖；备份：$backup"
  else
    [[ ! -e "$config" && ! -L "$config" ]] || fail 'Gem 配置目标已出现，未覆盖。'
  fi
  cat "$stage" > "$config" || fail "Gem 配置写入失败；备份：${backup:-原文件不存在}"
  rm -- "$stage"
  run_logged "$GEM_BIN" --config-file "$config" sources --list || fail "Gem 软件源复检失败；备份：${backup:-原文件不存在}"
  log "✔ Gem 软件源已保存；原配置备份：${backup:-原文件不存在}"
}
# 系统与不可写环境只读，避免用 sudo 修改 macOS 自带工具链。
gem_mutation_allowed() {
  if [[ "$GEM_RUBY" == /usr/bin/ruby || "$GEM_RUBY" == /System/* || "$GEM_BIN" == /usr/bin/gem || "$GEM_HOME_RESOLVED" == /Library/Ruby/* || "$GEM_HOME_RESOLVED" == /System/* ]]; then
    log '⚠ 当前是系统 Ruby / Gem 环境，仅检查和可选用户软件源配置；请先安装用户 Ruby 再升级。'
    return 1
  fi
  [[ -d "$GEM_HOME_RESOLVED" && -w "$GEM_HOME_RESOLVED" ]] || { log "⚠ Gem Home 不可写，未提权：$GEM_HOME_RESOLVED"; return 1; }
}
# 分别询问 RubyGems、本环境 Gem 更新及清理，不将清理默认为升级步骤。
update_gem_environment() {
  gem_mutation_allowed || return 0
  if ask_any_to_run '是否升级当前用户 RubyGems 本体？'; then
    show_source '升级' RubyGems "$("$GEM_BIN" sources --list)" "$GEM_HOME_RESOLVED"
    run_logged "$GEM_BIN" update --system || fail 'RubyGems 升级失败。'
    run_logged "$GEM_BIN" --version || fail 'RubyGems 升级后复检失败。'
  fi
  if ask_any_to_run '是否更新当前环境全部已安装 Gem？'; then
    show_source '更新' '当前环境全部 Gem' "$("$GEM_BIN" sources --list)" "$GEM_HOME_RESOLVED"
    run_logged "$GEM_BIN" update || fail 'Gem 软件包更新失败。'
  fi
  if confirm_yes "是否删除 $GEM_HOME_RESOLVED 中旧版本 Gem？可能影响仍依赖旧版本的项目。"; then
    run_logged "$GEM_BIN" cleanup || fail '旧版 Gem 清理失败。'
  fi
}
# 编排确认、运行准备和各项业务步骤。
main() {
  show_script_intro_and_wait # 首先展示内置自述，确认前不产生写入。
  initialize_script_runtime # 确认后初始化路径、日志和纯文本命令输出。
  inspect_gem_environment # 检查 RubyGems 和现有软件源。
  configure_gem_source # 按 YES 确认备份并配置软件源。
  update_gem_environment # 保护系统 Ruby 并分别询问用户 Gem 操作。
  report_completion # 输出所选步骤的结束位置与日志。
}

main "$@"

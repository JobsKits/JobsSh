#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】升级Ruby环境.sh
# - 核心用途：按当前管理来源升级 Homebrew / rbenv Ruby，保护系统 Ruby。
# - 影响范围：可能安装/升级用户 Ruby；改默认版本或 Shell PATH 前必须输入 YES。
# - 运行提示：先展示自述，回车继续；普通写操作回车跳过，Ctrl+C 或 EOF 取消。
# shell: zsh
SCRIPT_SOURCE="${(%):-%x}"
# 在任何写入前说明用途与风险，并阻止无交互运行。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】升级Ruby环境.sh'
  print -r -- '核心用途：按当前管理来源升级 Homebrew / rbenv Ruby，保护系统 Ruby。'
  print -r -- '影响范围：可能安装/升级用户 Ruby；改默认版本或 Shell PATH 前必须输入 YES。'
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
# 输出 Homebrew 诊断，避免混入命令路径返回值。
jobs_brew_note() {
  print -u2 -r -- "ℹ $*"
}
# 发现候选后验证命令层和真实安装前缀。
jobs_brew_candidate_ok() {
  local candidate="$1" prefix
  [[ -n "$candidate" && -x "$candidate" ]] || return 1
  HOMEBREW_NO_AUTO_UPDATE=1 "$candidate" --version >/dev/null 2>&1 || return 1
  prefix="$("$candidate" --prefix 2>/dev/null)" || return 1
  [[ "$prefix" == /* && -d "$prefix" ]] || return 1
  HOMEBREW_NO_AUTO_UPDATE=1 "$candidate" config >/dev/null 2>&1
}
# 按当前 PATH、系统前缀和已知用户前缀复用健康安装。
jobs_brew_find() {
  local candidate
  local -a candidates
  candidates=("$(command -v brew 2>/dev/null)" "${JOBS_HOMEBREW_BIN:-}" /opt/homebrew/bin/brew /usr/local/bin/brew
    "${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}/bin/brew" "$HOME/.homebrew/bin/brew")
  for candidate in "${candidates[@]}"; do
    if jobs_brew_candidate_ok "$candidate"; then
      print -r -- "$candidate"
      return 0
    fi
  done
  return 1
}
# 按架构计算系统目录，支持范围由官方安装器复核。
jobs_brew_system_prefix() {
  case "$(/usr/bin/uname -m)" in
    arm64) print -r -- /opt/homebrew ;;
    x86_64) print -r -- /usr/local ;;
    *) return 1 ;;
  esac
}
# 明确选择 Homebrew 安装位置，回车只表示选择用户路径。
jobs_brew_choose_installation() {
  local answer="" system_prefix
  system_prefix="$(jobs_brew_system_prefix)" || fail '不支持的 CPU 架构。'
  log "⚠ Homebrew 缺失或损坏，输入 YES 选择系统目录 $system_prefix；其它输入或回车选择 ${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}。"
  log '系统目录安装器可能请求管理员密码；用户目录不使用 sudo，非标准前缀的兼容性由 Homebrew 决定。'
  print -n -r -- '➤ 安装路径选择：'
  IFS= read -r answer || fail '输入结束，未执行安装。'
  if [[ "$answer" == YES ]]; then
    JOBS_HOMEBREW_INSTALL_MODE=system
  else
    JOBS_HOMEBREW_INSTALL_MODE=user
  fi
}
# 下载并运行官方安装器，不在失败后切换到其它路径。
jobs_brew_install_system() {
  local installer result=0 prefix
  prefix="$(jobs_brew_system_prefix)" || return 1
  /usr/bin/curl --version >/dev/null 2>&1 || fail '缺少健康 curl，无法获取 Homebrew 安装器。'
  installer="$(mktemp "${TMPDIR:-/tmp}/jobs-homebrew-install.XXXXXX")" || return 1
  show_source '安装' Homebrew https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh "$prefix"
  log "安装器仓库：${HOMEBREW_BREW_GIT_REMOTE:-https://github.com/Homebrew/brew}"
  if run_logged /usr/bin/curl -fL --connect-timeout 10 --max-time 120 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"; then
    run_logged /bin/bash "$installer" || result=$?
  else
    result=1
  fi
  rm -- "$installer"
  (( result == 0 )) || return "$result"
  JOBS_HOMEBREW_BIN="$prefix/bin/brew"
  jobs_brew_candidate_ok "$JOBS_HOMEBREW_BIN"
}
# 将官方稳定版本装到用户目录，不覆盖非空或损坏目录。
jobs_brew_install_user() {
  local prefix="${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}" stage release_tag git_bin
  [[ "$prefix" == /* && "$prefix" != / && "$prefix" != *[[:space:]:]* ]] || fail "用户前缀必须是无空白、冒号的绝对路径：$prefix"
  [[ ! -L "$prefix" && ( ! -e "$prefix" || ( -d "$prefix" && -z "$(ls -A "$prefix")" ) ) ]] || fail "用户安装目标非空，未覆盖：$prefix"
  git_bin="$(command -v git 2>/dev/null)"
  [[ -n "$git_bin" ]] && "$git_bin" --version >/dev/null 2>&1 || fail '用户安装缺少可用 Git / Command Line Tools。'
  /usr/bin/curl --version >/dev/null 2>&1 || fail '缺少健康 curl。'
  export HOMEBREW_NO_SUDO=1
  show_source '查询稳定版本' Homebrew https://api.github.com/repos/Homebrew/brew/releases/latest "$prefix"
  mkdir -p "${prefix:h}" || return 1
  stage="$(mktemp -d "${prefix:h}/.jobs-homebrew.XXXXXX")" || return 1
  if ! run_logged /usr/bin/curl -fL --connect-timeout 10 --max-time 60 https://api.github.com/repos/Homebrew/brew/releases/latest -o "$stage/release.json"; then
    rm -r -- "$stage"
    return 1
  fi
  release_tag="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "$stage/release.json" | head -n 1)"
  [[ "$release_tag" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || fail "无法解析 Homebrew 稳定版本；临时资料：$stage"
  show_source '安装' "Homebrew $release_tag" https://github.com/Homebrew/brew.git "$prefix"
  if ! run_logged env GIT_TERMINAL_PROMPT=0 "$git_bin" -c http.lowSpeedLimit=1 -c http.lowSpeedTime=60 clone --depth 1 --branch "$release_tag" --single-branch https://github.com/Homebrew/brew.git "$stage/brew" ||
     ! run_logged "$git_bin" -C "$stage/brew" checkout -b stable ||
     ! run_logged "$git_bin" -C "$stage/brew" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' ||
     ! mkdir -p "$stage/brew/Cellar" "$stage/brew/Caskroom" "$stage/brew/etc" "$stage/brew/var"; then
    rm -r -- "$stage"
    return 1
  fi
  if [[ -d "$prefix" ]] && ! rmdir -- "$prefix"; then
    rm -r -- "$stage"
    return 1
  fi
  mv "$stage/brew" "$prefix" || return 1
  rm -r -- "$stage"
  JOBS_HOMEBREW_BIN="$prefix/bin/brew"
  jobs_brew_candidate_ok "$JOBS_HOMEBREW_BIN"
}
# 激活本进程的 Homebrew 环境，不隐式写入配置或更新软件。
jobs_brew_activate() {
  local brew_env
  brew_env="$("$JOBS_HOMEBREW_BIN" shellenv)" || return 1
  eval "$brew_env" || return 1
  JOBS_HOMEBREW_PREFIX="$("$JOBS_HOMEBREW_BIN" --prefix)" || return 1
  export PATH="$JOBS_HOMEBREW_PREFIX/bin:$JOBS_HOMEBREW_PREFIX/sbin:$PATH"
  rehash
  jobs_brew_candidate_ok "$JOBS_HOMEBREW_BIN"
}
# 仅在用户确认后备份并持久化 Homebrew 的受控 shellenv 块。
jobs_brew_save_shellenv() {
  local profile="$HOME/.zprofile" content
  [[ "${SHELL:t}" != bash ]] || profile="$HOME/.bash_profile"
  confirm_yes "将 Homebrew shellenv 写入 $profile（先备份）？" || return 0
  content='eval "$('"${(q)JOBS_HOMEBREW_BIN}"' shellenv)"'
  write_managed_block "$profile" 'Homebrew shellenv' "$content"
}
# 只有确需 Homebrew 的执行分支才自检并按确认安装一次。
jobs_brew_install_or_exit() {
  local installed=0
  if ! JOBS_HOMEBREW_BIN="$(jobs_brew_find)"; then
    jobs_brew_choose_installation
    ask_any_to_run '是否安装所选路径的 Homebrew？' || fail '已跳过 Homebrew 安装，无法继续此业务分支。'
    case "$JOBS_HOMEBREW_INSTALL_MODE" in
      system) jobs_brew_install_system || fail 'Homebrew 系统安装或复检失败，未切换路径。' ;;
      user) jobs_brew_install_user || fail 'Homebrew 用户安装或复检失败，未切换路径。' ;;
      *) fail 'Homebrew 安装选择无效。' ;;
    esac
    installed=1
  fi
  jobs_brew_activate || fail "Homebrew 复检失败：$JOBS_HOMEBREW_BIN"
  (( installed == 0 )) || jobs_brew_save_shellenv
}
# 输出当前运行结束位置，便于离线排查。
report_completion() {
  log "✔ 所选步骤已处理；日志：$LOG_FILE"
}
# 解析当前 Ruby 真实路径与管理器，保护系统 Ruby 和未知来源。
inspect_ruby_environment() {
  RUBY_BIN="$(command -v ruby 2>/dev/null)"
  RUBY_REAL=""
  RBENV_BIN="$(command -v rbenv 2>/dev/null)"
  RBENV_ROOT_RESOLVED=""
  if [[ -n "$RUBY_BIN" ]] && "$RUBY_BIN" --version >/dev/null 2>&1; then
    RUBY_REAL="$("$RUBY_BIN" -rrbconfig -e 'print RbConfig.ruby')" || fail '无法解析 Ruby 实际路径。'
    run_logged "$RUBY_BIN" --version || fail 'Ruby 版本检查失败。'
    log "ℹ Ruby 入口：$RUBY_BIN；实际运行时：$RUBY_REAL"
  else
    log '⚠ 未发现健康 Ruby。'
  fi
  if [[ -n "$RBENV_BIN" ]] && "$RBENV_BIN" --version >/dev/null 2>&1; then
    RBENV_ROOT_RESOLVED="$("$RBENV_BIN" root)" || fail 'rbenv 根目录检查失败。'
  fi
}
# 为当前 Homebrew Ruby 写入可撤回的用户 PATH 块。
configure_ruby_path() {
  local prefix="$1" profile="$HOME/.zprofile" gem_bin content
  [[ "${SHELL:t}" != bash ]] || profile="$HOME/.bash_profile"
  gem_bin="$("$prefix/bin/ruby" -rrubygems -e 'print Gem.bindir')" || fail '无法读取当前 Ruby 的 Gem bin 目录。'
  export PATH="$prefix/bin:$gem_bin:$PATH"
  rehash
  confirm_yes "将 Ruby / Gem PATH 写入 $profile（先备份）？" || return 0
  content="export PATH=${(q)prefix}/bin:${(q)gem_bin}:\$PATH"
  write_managed_block "$profile" Ruby "$content"
}
# 通过 Homebrew 安装或升级当前公式，系统 Ruby 不受改写。
manage_homebrew_ruby() {
  local formula="${1:-ruby}" prefix action
  jobs_brew_install_or_exit
  prefix="$("$JOBS_HOMEBREW_BIN" --prefix "$formula")" || fail "无法解析 $formula 前缀。"
  if "$prefix/bin/ruby" --version >/dev/null 2>&1; then
    action=upgrade
  elif "$JOBS_HOMEBREW_BIN" list --versions "$formula" >/dev/null 2>&1; then
    action=reinstall
  else
    action=install
  fi
  ask_any_to_run "是否执行 $action $formula？" || return 0
  show_brew_source "$action" "$formula" "$prefix"
  run_logged "$JOBS_HOMEBREW_BIN" "$action" "$formula" || fail "$action $formula 失败。"
  "$prefix/bin/ruby" --version >/dev/null 2>&1 && "$prefix/bin/gem" --version >/dev/null 2>&1 || fail 'Homebrew Ruby / Gem 安装后复检失败。'
  run_logged "$prefix/bin/ruby" --version || fail 'Ruby 复检失败。'
  configure_ruby_path "$prefix"
}
# rbenv 编译能力缺失时仅补充所需 ruby-build，不强制引入其它管理器。
ensure_ruby_build() {
  "$RBENV_BIN" install --list >/dev/null 2>&1 && return 0
  ask_any_to_run 'rbenv 缺少健康 ruby-build，是否通过 Homebrew 安装/修复？' || fail '已跳过 ruby-build，无法继续 rbenv 安装。'
  jobs_brew_install_or_exit
  local action=install
  "$JOBS_HOMEBREW_BIN" list --versions ruby-build >/dev/null 2>&1 && action=reinstall
  show_brew_source "$action" ruby-build "$JOBS_HOMEBREW_PREFIX"
  run_logged "$JOBS_HOMEBREW_BIN" "$action" ruby-build || fail 'ruby-build 安装失败。'
  rehash
  "$RBENV_BIN" install --list >/dev/null 2>&1 || fail 'ruby-build 安装后复检失败。'
}
# 安装 rbenv 官方可用稳定版本，只有 YES 才修改用户默认版本。
manage_rbenv_ruby() {
  local versions latest version backup="" version_file="$RBENV_ROOT_RESOLVED/version"
  ask_any_to_run '是否通过现有 rbenv 安装或切换稳定 Ruby？' || return 0
  ensure_ruby_build
  versions="$("$RBENV_BIN" install --list)" || fail 'rbenv 版本列表获取失败。'
  latest="$(print -r -- "$versions" | awk '/^[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$/ { gsub(/[[:space:]]/, ""); print }' | sort -t . -k1,1n -k2,2n -k3,3n | tail -n 1)"
  [[ -n "$latest" ]] || fail '没有解析到稳定 Ruby 版本，请更新 ruby-build 后重试。'
  log "ℹ ruby-build 可安装版本："$'\n'"$versions"
  print -n -r -- "选择稳定 Ruby 版本（默认 $latest）："
  IFS= read -r version || fail '输入结束，未安装 Ruby。'
  version="${version:-$latest}"
  [[ "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || fail '只接受稳定 Ruby 的完整版本号。'
  print -r -- "$versions" | awk '{ print $1 }' | grep -Fxq "$version" || fail "版本不在 ruby-build 当前列表：$version"
  if ! env RBENV_VERSION="$version" "$RBENV_BIN" exec ruby --version >/dev/null 2>&1; then
    show_source '安装' "Ruby $version" 'https://github.com/rbenv/ruby-build；Ruby 归档地址由 ruby-build 定义解析' "$RBENV_ROOT_RESOLVED/versions/$version"
    [[ -z "${RUBY_BUILD_MIRROR_URL:-}" ]] || log "ruby-build 镜像：$RUBY_BUILD_MIRROR_URL"
    [[ -z "${RUBY_BUILD_TARBALL_OVERRIDE:-}" ]] || log "ruby-build 归档覆盖：$RUBY_BUILD_TARBALL_OVERRIDE"
    run_logged "$RBENV_BIN" install "$version" || fail "rbenv 安装 Ruby $version 失败；没有覆盖或删除旧版本。"
  fi
  run_logged env RBENV_VERSION="$version" "$RBENV_BIN" exec ruby --version || fail 'rbenv Ruby 安装后复检失败。'
  run_logged env RBENV_VERSION="$version" "$RBENV_BIN" exec gem --version || fail 'rbenv Gem 安装后复检失败。'
  if confirm_yes "是否将 rbenv 用户默认版本设为 $version？会影响未指定 .ruby-version / RBENV_VERSION 的项目。"; then
    [[ ! -L "$version_file" && ( ! -e "$version_file" || -f "$version_file" ) ]] || fail 'rbenv 默认版本文件不是普通文件，未修改。'
    if [[ -f "$version_file" ]]; then
      backup="$(mktemp "${version_file}.jobs-backup.XXXXXX")" || fail '默认版本备份失败。'
      cp -p "$version_file" "$backup" || fail '默认版本备份失败。'
    fi
    run_logged "$RBENV_BIN" global "$version" || fail "rbenv 默认版本切换失败；备份：${backup:-原文件不存在}"
    [[ "$("$RBENV_BIN" global)" == "$version" ]] || fail 'rbenv 默认版本复检失败。'
    log "✔ rbenv 默认版本已设置；恢复备份：${backup:-原文件不存在，可移除新版本文件恢复 system}"
  fi
}
# 按实际管理来源路由，未知管理器不猜测安装与升级方式。
upgrade_selected_ruby() {
  local brew_candidate prefix formula=ruby relative
  if [[ -n "$RBENV_ROOT_RESOLVED" && ( "$RUBY_BIN" == "$RBENV_ROOT_RESOLVED/shims/"* || "$RUBY_REAL" == "$RBENV_ROOT_RESOLVED/versions/"* ) ]]; then
    manage_rbenv_ruby
    return
  fi
  if brew_candidate="$(jobs_brew_find)"; then
    prefix="$("$brew_candidate" --prefix)" || fail 'Homebrew 前缀检查失败。'
    relative=""
    if [[ "$RUBY_REAL" == "$prefix/Cellar/"* ]]; then
      relative="${RUBY_REAL#"$prefix/Cellar/"}"
    elif [[ "$RUBY_REAL" == "$prefix/opt/"* ]]; then
      relative="${RUBY_REAL#"$prefix/opt/"}"
    fi
    formula="${relative%%/*}"
    if [[ "$formula" == ruby || "$formula" =~ '^ruby@[0-9]+(\.[0-9]+)*$' ]]; then
      manage_homebrew_ruby "$formula"
      return
    fi
  fi
  if [[ -z "$RUBY_REAL" || "$RUBY_REAL" == /usr/bin/ruby || "$RUBY_REAL" == /System/* ]]; then
    log 'ℹ 系统 Ruby 保持只读；可另装用户 Homebrew Ruby，不执行 sudo gem update。'
    ask_any_to_run '是否准备独立的 Homebrew Ruby？' || return 0
    manage_homebrew_ruby ruby
    return
  fi
  log "⚠ Ruby 来自未识别管理器：$RUBY_REAL；请使用原管理器升级，未修改该安装。"
}
# 编排确认、运行准备和各项业务步骤。
main() {
  show_script_intro_and_wait # 首先展示内置自述，确认前不产生写入。
  initialize_script_runtime # 确认后初始化路径、日志和纯文本命令输出。
  inspect_ruby_environment # 识别实际 Ruby 路径与版本管理器。
  upgrade_selected_ruby # 沿当前安装来源升级并保护系统 Ruby。
  report_completion # 输出所选步骤的结束位置与日志。
}

main "$@"

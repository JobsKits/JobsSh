#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】JobsSql.sh
# - 核心用途：安装或升级 Homebrew MySQL，按需启动和交互登录。
# - 影响范围：Homebrew、所选 MySQL 公式及服务；保留已有数据库与认证配置。
# - 运行提示：先阅读内置自述并回车；普通动作回车跳过，危险动作精确输入 YES。
# shell: zsh
# 打印固定内置自述，确认前只做终端展示。
# >>> Jobs terminal style protection v1 >>>
# 临时保护当前终端配色，业务进程自行管理原有退出清理。
jobs_terminal_style_run() {
    # 无法可靠保存原色时，沿用脚本已有的纯文本约定。
    jobs_terminal_style_plain() {
        PLAIN_OUTPUT=1
        NO_COLOR=1
        FORCE_COLOR=0
        CLICOLOR=0
        ANSI_COLORS_DISABLED=1
        npm_config_color=false
        export PLAIN_OUTPUT NO_COLOR FORCE_COLOR CLICOLOR ANSI_COLORS_DISABLED npm_config_color
        if "$@"; then
            jobs_style_exit_status=0
        else
            jobs_style_exit_status=$?
        fi
        exit "$jobs_style_exit_status"
    }
    if [ ! -t 0 ] || [ ! -t 1 ] || [ -z "${TERM:-}" ] ||
       [ "${TERM:-}" = dumb ] || [ "${NO_COLOR+x}" = x ] ||
       [ "${PLAIN_OUTPUT:-0}" = 1 ] || [ "${IS_SOURCETREE_RUNTIME:-0}" = 1 ] ||
       env | LC_ALL=C grep -qiE '^(SOURCETREE|SOURCE_TREE)'; then
        if "$@"; then
            jobs_style_exit_status=0
        else
            jobs_style_exit_status=$?
        fi
        exit "$jobs_style_exit_status"
    fi
    if [ -n "${TMUX:-}${STY:-}" ]; then
        jobs_terminal_style_plain "$@"
    fi
    jobs_style_tty=$(tty 2>/dev/null) || jobs_terminal_style_plain "$@"
    if ! ps -o pgid= -o tpgid= -p "$$" 2>/dev/null |
         LC_ALL=C awk 'NF == 2 && $1 == $2 && $1 > 0 { foreground = 1 } END { exit !foreground }'; then
        jobs_terminal_style_plain "$@"
    fi
    case ${JOBS_TERMINAL_STYLE_OWNER:-} in
        ''|*[!0-9]*) ;;
        *)
            if [ "${JOBS_TERMINAL_STYLE_TTY:-}" = "$jobs_style_tty" ] &&
               kill -0 "$JOBS_TERMINAL_STYLE_OWNER" 2>/dev/null; then
                if "$@"; then
                    jobs_style_exit_status=0
                else
                    jobs_style_exit_status=$?
                fi
                exit "$jobs_style_exit_status"
            fi
            ;;
    esac
    jobs_style_stty=$(stty -g 2>/dev/null < /dev/tty) || jobs_terminal_style_plain "$@"
    jobs_style_saved=''
    jobs_style_saved_rows=''
    jobs_style_applied_rows=''
    jobs_style_changed=0
    jobs_style_applied_complete=0
    jobs_style_query_active=0
    jobs_style_recovery=''
    jobs_style_exit_status=0
    jobs_style_esc=$(printf '\033')
    jobs_style_bel=$(printf '\007')
    # 只接受本次请求对应的 RGB 响应；非协议输入使本次探测失败。
    jobs_terminal_style_query() {
        jobs_style_query_key=$1
        printf '\033]%s;?\007' "$jobs_style_query_key" > /dev/tty || return 1
        jobs_style_reply=''
        for jobs_style_attempt in 1 2 3; do
            jobs_style_piece=$(dd bs=256 count=1 2>/dev/null < /dev/tty)
            jobs_style_reply=$jobs_style_reply$jobs_style_piece
            case $jobs_style_reply in
                *"$jobs_style_bel"|*"$jobs_style_esc\\") break ;;
                '') ;;
                "$jobs_style_esc"*) ;;
                *) break ;;
            esac
        done
        case $jobs_style_reply in
            "$jobs_style_esc]$jobs_style_query_key;rgb:"*"$jobs_style_bel")
                jobs_style_rgb=${jobs_style_reply#"$jobs_style_esc]$jobs_style_query_key;rgb:"}
                jobs_style_rgb=${jobs_style_rgb%"$jobs_style_bel"}
                ;;
            "$jobs_style_esc]$jobs_style_query_key;rgb:"*"$jobs_style_esc\\")
                jobs_style_rgb=${jobs_style_reply#"$jobs_style_esc]$jobs_style_query_key;rgb:"}
                jobs_style_rgb=${jobs_style_rgb%"$jobs_style_esc\\"}
                ;;
            *) return 1 ;;
        esac
        jobs_style_normalized=$(printf '%s\n' "$jobs_style_rgb" | LC_ALL=C awk -F/ '
            NF != 3 { exit 1 }
            {
                for (i = 1; i <= 3; i++) {
                    h = tolower($i)
                    if (length(h) < 1 || length(h) > 4 || h ~ /[^0-9a-f]/) exit 1
                    n = 0
                    for (j = 1; j <= length(h); j++) n = n * 16 + index("0123456789abcdef", substr(h, j, 1)) - 1
                    value[i] = int(n * 65535 / (16 ^ length(h) - 1) + 0.5)
                }
                printf "%d/%d/%d", value[1], value[2], value[3]
            }
        ') || return 1
        [ -n "$jobs_style_normalized" ]
    }
    # 查询可用不代表终端允许改色，按目标值核对实际生效结果。
    jobs_terminal_style_accepts_target() {
        jobs_style_requested_hex=''
        case $1 in
            10|12) jobs_style_requested_hex=ffffff ;;
            11) jobs_style_requested_hex=000000 ;;
            '4;'*)
                jobs_style_requested_index=0
                for jobs_style_requested_color in 000000 ff5f56 5fd787 ffd75f 5fafff d787ff 5fd7ff eeeeee 9e9e9e ff8787 87ffaf ffff87 87bfff ffafff afffff ffffff; do
                    if [ "4;$jobs_style_requested_index" = "$1" ]; then
                        jobs_style_requested_hex=$jobs_style_requested_color
                        break
                    fi
                    jobs_style_requested_index=$((jobs_style_requested_index + 1))
                done
                ;;
        esac
        [ -n "$jobs_style_requested_hex" ] || return 1
        printf '%s|%s\n' "$jobs_style_normalized" "$jobs_style_requested_hex" | LC_ALL=C awk -F'|' '
            function hexbyte(h) {
                return (index("0123456789abcdef", substr(h, 1, 1)) - 1) * 16 + index("0123456789abcdef", substr(h, 2, 1)) - 1
            }
            {
                if (split($1, actual, "/") != 3 || length($2) != 6) exit 1
                for (i = 1; i <= 3; i++) {
                    difference = actual[i] - hexbyte(substr($2, i * 2 - 1, 2)) * 257
                    if (difference < -255 || difference > 255) exit 1
                }
            }
        '
    }
    # 检测到后续改色时只恢复仍由本次保护持有的项，保留独立恢复入口。
    jobs_terminal_style_cleanup() {
        jobs_style_result=$1
        trap '' HUP INT TERM
        if [ "$jobs_style_query_active" = 1 ]; then
            stty "$jobs_style_stty" 2>/dev/null < /dev/tty || :
            jobs_style_query_active=0
        fi
        if [ "$jobs_style_changed" = 1 ]; then
            jobs_style_cleanup_ok=0
            jobs_style_conflicts=''
            jobs_style_restore_safe=''
            if [ "$jobs_style_applied_complete" = 1 ]; then
                jobs_style_stty=$(stty -g 2>/dev/null < /dev/tty) || jobs_style_stty=''
                if [ -n "$jobs_style_stty" ] && stty -echo -icanon min 0 time 1 2>/dev/null < /dev/tty; then
                    jobs_style_query_active=1
                    jobs_style_cleanup_ok=1
                    while IFS='|' read -r jobs_style_key jobs_style_expected jobs_style_original; do
                        [ -n "$jobs_style_key" ] || continue
                        if ! jobs_terminal_style_query "$jobs_style_key"; then
                            jobs_style_cleanup_ok=0
                            break
                        fi
                        if [ "$jobs_style_normalized" = "$jobs_style_expected" ]; then
                            jobs_style_restore_safe=$jobs_style_restore_safe$jobs_style_original
                        else
                            jobs_style_conflicts="$jobs_style_conflicts $jobs_style_key"
                        fi
                    done <<JOBS_STYLE_APPLIED
$jobs_style_applied_rows
JOBS_STYLE_APPLIED
                    stty "$jobs_style_stty" 2>/dev/null < /dev/tty || jobs_style_cleanup_ok=0
                    jobs_style_query_active=0
                fi
            fi
            if [ "$jobs_style_cleanup_ok" = 1 ] && printf '%s\033[0m' "$jobs_style_restore_safe" > /dev/tty; then
                if [ -z "$jobs_style_conflicts" ]; then
                    rm -f "$jobs_style_recovery"
                    rmdir "${jobs_style_recovery%/*}" 2>/dev/null || :
                else
                    printf '检测到运行期间的配色变更，已保留这些项：%s\n' "$jobs_style_conflicts" >&2
                    printf '确认要覆盖后续改色时才使用恢复入口：sh "%s"\n' "$jobs_style_recovery" >&2
                    [ "$jobs_style_result" -ne 0 ] || jobs_style_result=1
                fi
            else
                printf '终端配色未能安全自动恢复；确认覆盖当前配色后可运行：sh "%s"\n' "$jobs_style_recovery" >&2
                [ "$jobs_style_result" -ne 0 ] || jobs_style_result=1
            fi
        fi
        if [ "${2:-}" = continue ]; then
            jobs_style_cleanup_status=$jobs_style_result
            return 0
        fi
        exit "$jobs_style_result"
    }
    trap 'jobs_terminal_style_cleanup "$jobs_style_exit_status"' 0
    trap 'jobs_style_exit_status=129; exit 129' HUP
    trap 'jobs_style_exit_status=130; exit 130' INT
    trap 'jobs_style_exit_status=143; exit 143' TERM
    if ! stty -echo -icanon min 0 time 1 2>/dev/null < /dev/tty; then
        jobs_terminal_style_plain "$@"
    fi
    jobs_style_query_active=1
    jobs_style_probe_ok=1
    for jobs_style_key in 10 11 12 '4;0' '4;1' '4;2' '4;3' '4;4' '4;5' '4;6' '4;7' '4;8' '4;9' '4;10' '4;11' '4;12' '4;13' '4;14' '4;15'; do
        if ! jobs_terminal_style_query "$jobs_style_key"; then
            jobs_style_probe_ok=0
            break
        fi
        jobs_style_saved=$jobs_style_saved$jobs_style_reply
        jobs_style_saved_rows="$jobs_style_saved_rows$jobs_style_key|$jobs_style_reply
"
    done
    stty "$jobs_style_stty" 2>/dev/null < /dev/tty || { jobs_style_exit_status=1; exit 1; }
    jobs_style_query_active=0
    if [ "$jobs_style_probe_ok" != 1 ]; then
        printf '%s\n' '终端不支持完整配色保存，或启动时收到其它输入；保留原配色并使用纯文本。' >&2
        jobs_terminal_style_plain "$@"
    fi
    jobs_style_recovery_dir=$(umask 077; mktemp -d "${TMPDIR:-/tmp}/jobs-terminal-style.XXXXXX") || jobs_terminal_style_plain "$@"
    jobs_style_recovery=$jobs_style_recovery_dir/restore.sh
    if ! (umask 077; {
        printf '#!/bin/sh\n'
        printf '[ -t 0 ] && [ "$(tty)" = '\''%s'\'' ] || { printf '\''请在原终端运行恢复入口。\\n'\'' >&2; exit 1; }\n' "$jobs_style_tty"
        printf 'printf '\''本操作会覆盖此终端当前配色。确认恢复脚本启动前的配色，请输入 YES：'\'' >&2\n'
        printf 'IFS= read -r jobs_restore_choice\n[ "$jobs_restore_choice" = YES ] || exit 1\n'
        printf 'printf '\''%%s\\033[0m'\'' '\''%s'\'' > /dev/tty\n' "$jobs_style_saved"
    } > "$jobs_style_recovery"); then
        printf '%s\n' '无法保存终端配色恢复入口；保留原配色并使用纯文本。' >&2
        jobs_terminal_style_plain "$@"
    fi
    printf '正在准备本次终端临时配色；强退后恢复入口：sh "%s"\n' "$jobs_style_recovery" >&2
    jobs_style_changed=1
    printf '\033]10;#ffffff\007\033]11;#000000\007\033]12;#ffffff\007' > /dev/tty
    jobs_style_index=0
    for jobs_style_color in 000000 ff5f56 5fd787 ffd75f 5fafff d787ff 5fd7ff eeeeee 9e9e9e ff8787 87ffaf ffff87 87bfff ffafff afffff ffffff; do
        printf '\033]4;%s;#%s\007' "$jobs_style_index" "$jobs_style_color" > /dev/tty
        jobs_style_index=$((jobs_style_index + 1))
    done
    printf '\033[0m' > /dev/tty
    jobs_style_stty=$(stty -g 2>/dev/null < /dev/tty) || { jobs_style_exit_status=1; exit 1; }
    stty -echo -icanon min 0 time 1 2>/dev/null < /dev/tty || { jobs_style_exit_status=1; exit 1; }
    jobs_style_query_active=1
    jobs_style_probe_ok=1
    jobs_style_targets_ok=1
    while IFS='|' read -r jobs_style_key jobs_style_original; do
        [ -n "$jobs_style_key" ] || continue
        if ! jobs_terminal_style_query "$jobs_style_key"; then
            jobs_style_probe_ok=0
            break
        fi
        jobs_style_applied_rows="$jobs_style_applied_rows$jobs_style_key|$jobs_style_normalized|$jobs_style_original
"
        if ! jobs_terminal_style_accepts_target "$jobs_style_key"; then
            jobs_style_targets_ok=0
        fi
    done <<JOBS_STYLE_ORIGINAL
$jobs_style_saved_rows
JOBS_STYLE_ORIGINAL
    stty "$jobs_style_stty" 2>/dev/null < /dev/tty || { jobs_style_exit_status=1; exit 1; }
    jobs_style_query_active=0
    if [ "$jobs_style_probe_ok" != 1 ]; then
        printf '%s\n' '无法核实本次临时配色，已停止启动业务。' >&2
        jobs_style_exit_status=1
        exit 1
    fi
    jobs_style_applied_complete=1
    if [ "$jobs_style_targets_ok" != 1 ]; then
        jobs_terminal_style_cleanup 0 continue
        jobs_style_changed=0
        if [ "$jobs_style_cleanup_status" != 0 ]; then
            jobs_style_exit_status=1
            exit 1
        fi
        trap 'jobs_style_exit_status=129; exit 129' HUP
        trap 'jobs_style_exit_status=130; exit 130' INT
        trap 'jobs_style_exit_status=143; exit 143' TERM
        printf '%s\n' '终端未接受本次配色，已恢复原配色并使用纯文本。' >&2
        jobs_terminal_style_plain "$@"
    fi
    printf '%s\n' '本次终端已临时使用黑底白字。' >&2
    JOBS_TERMINAL_STYLE_TTY=$jobs_style_tty
    JOBS_TERMINAL_STYLE_OWNER=$$
    export JOBS_TERMINAL_STYLE_TTY JOBS_TERMINAL_STYLE_OWNER
    if "$@"; then
        jobs_style_exit_status=0
    else
        jobs_style_exit_status=$?
    fi
    exit "$jobs_style_exit_status"
}
# 仅监督直接执行的入口；被 source 时不切换配色、不重新执行业务。
jobs_terminal_style_bootstrap() {
    jobs_style_bootstrap_script=$1
    shift
    if [ -n "${ZSH_VERSION:-}" ]; then
        case ${ZSH_EVAL_CONTEXT:-} in
            *:file|*:file:*) return 0 ;;
        esac
    elif [ -n "${BASH_VERSION:-}" ] && [ "${BASH_SOURCE:-$jobs_style_bootstrap_script}" != "$jobs_style_bootstrap_script" ]; then
        return 0
    fi
    if [ "${JOBS_TERMINAL_STYLE_REEXEC:-}" = "$jobs_style_bootstrap_script" ]; then
        unset JOBS_TERMINAL_STYLE_REEXEC
        return 0
    fi
    if [ ! -t 0 ] || [ ! -t 1 ] || [ -z "${TERM:-}" ] ||
       [ "${TERM:-}" = dumb ] || [ "${NO_COLOR+x}" = x ] ||
       [ "${PLAIN_OUTPUT:-0}" = 1 ] || [ "${IS_SOURCETREE_RUNTIME:-0}" = 1 ] ||
       [ -n "${TMUX:-}${STY:-}" ] ||
       env | LC_ALL=C grep -qiE '^(SOURCETREE|SOURCE_TREE)'; then
        return 0
    fi
    case ${JOBS_TERMINAL_STYLE_OWNER:-} in
        ''|*[!0-9]*) ;;
        *)
            if kill -0 "$JOBS_TERMINAL_STYLE_OWNER" 2>/dev/null &&
               [ "${JOBS_TERMINAL_STYLE_TTY:-}" = "$(tty 2>/dev/null)" ]; then
                return 0
            fi
            ;;
    esac
    JOBS_TERMINAL_STYLE_REEXEC=$jobs_style_bootstrap_script
    export JOBS_TERMINAL_STYLE_REEXEC
    jobs_terminal_style_run /bin/zsh "$jobs_style_bootstrap_script" "$@"
    jobs_style_bootstrap_result=$?
    exit "$jobs_style_bootstrap_result"
}
jobs_terminal_style_bootstrap "$0" "$@"
# <<< Jobs terminal style protection v1 <<<

# JOBS_INPUT_CHOICE_STYLE_BEGIN
# 只展示提示选项；不读取答案、不改变默认值、返回码或业务环境。
jobs_prompt_color_ready() {
  [ -z "${NO_COLOR+x}" ] && [ -n "${TERM:-}" ] && [ "${TERM:-}" != dumb ] &&
    [ "${PLAIN_OUTPUT:-0}" != 1 ] && [ "${IS_SOURCETREE_RUNTIME:-0}" != 1 ]
}
# 原生 awk 分段着色；任意/非空输入优先，括号内外沿用同一个选项。
jobs_prompt_format() {
  /usr/bin/awk -v color="${1:-0}" -v lines="${2:-0}" -v keep="${3:-0}" '
    function typedEnter(value, start, prefix) {
      prefix = substr(value, 1, start - 1)
      gsub(/[“”‘’「」『』"]/, "", prefix)
      gsub(sprintf("%c", 39), "", prefix)
      if (prefix ~ /(空格|[Ss][Pp][Aa][Cc][Ee])[[:space:]]*(后|再|并|[Tt][Hh][Ee][Nn])?[[:space:]]*$/) return 1
      return prefix ~ /(输入|键入|填写|[Tt]ype)[^；;|]*[[:alnum:]_+-]+[[:space:]]*(后|再|并)?[[:space:]]*$/
    }
    function greenPosition(value, token, start) {
      if (match(value, /(直接|仅|只需|只|按下|按)?[[:space:]]*(回车|回車)/)) {
        start = RSTART
        return typedEnter(value, start) ? 0 : start
      }
      if (!match(value, /(^|[^[:alnum:]_])([Ee][Nn][Tt][Ee][Rr]|[Rr][Ee][Tt][Uu][Rr][Nn])([^[:alnum:]_]|$)/)) return 0
      start = RSTART
      token = substr(value, RSTART, RLENGTH)
      match(token, /[Ee][Nn][Tt][Ee][Rr]|[Rr][Ee][Tt][Uu][Rr][Nn]/)
      start += RSTART - 1
      return typedEnter(value, start) ? 0 : start
    }
    function segment(value, inherited, start, kind, prefix, body, red, green, connector, left, right, splitAt) {
      if (value == "") return value
      kind = inherited
      start = 1
      if (!kind) {
        if (match(value, /(输入)?(任意|任何)(非空)?(字符|内容|输入|键)|非空(字符|内容|输入)?|其它输入|其他输入|[Tt]ype (anything|any[^ ]*)|[Pp]ress any key/)) {
          red = RSTART
        }
        green = greenPosition(value)
        if (red && green && green < red) {
          left = substr(value, 1, red - 1)
          right = substr(value, red)
          connector = ""
          if (match(left, /(或者|或)[[:space:]]*$/)) {
            connector = substr(left, RSTART)
            left = substr(left, 1, RSTART - 1)
          }
          return segment(left, 0) connector segment(right, 31)
        }
        if (red && green && red < green && match(value, /或[[:space:]]*(直接|仅|只需|只|按下|按)?(回车|回車)/)) {
          splitAt = RSTART
          return segment(substr(value, 1, splitAt - 1), 31) "或" segment(substr(value, splitAt + length("或")), 0)
        }
        if (red) {
          kind = 31
          start = red
        } else if (green) {
          kind = 32
          start = green
        }
      }
      if (!kind || !color) return value
      prefix = substr(value, 1, start - 1)
      body = substr(value, start)
      return prefix esc "[1;" kind "m" body esc "[0m"
    }
    function render(value, output, part, boundary, inherited, kind, consumed, depth, original) {
      original = value
      gsub(esc "\\[[0-9;]*m", "", value)
      if (color && keep && !greenPosition(value) && value !~ /(任意|任何|非空|其它输入|其他输入|[Tt]ype (anything|any[^ ]*)|[Pp]ress any key)/) return original
      output = ""
      inherited = 0
      depth = 0
      while (match(value, /[；;\/|，,、？?：:=＝（）()\[\]【】]/)) {
        part = substr(value, 1, RSTART - 1)
        boundary = substr(value, RSTART, RLENGTH)
        consumed = RSTART + RLENGTH
        output = output segment(part, inherited) boundary
        if (boundary ~ /[（(\[【]/) {
          depth++
          if (part ~ /(任意|任何|非空|其它输入|其他输入|[Tt]ype (anything|any[^ ]*)|[Pp]ress any key)/) inherited = 31
          else if (greenPosition(part)) inherited = 32
        } else if (boundary ~ /[）)\]】]/) {
          if (depth) depth--
        } else if (boundary ~ /[：:=＝]/) {
          if (!inherited) {
            if (part ~ /(任意|任何|非空|其它输入|其他输入)/) inherited = 31
            else if (greenPosition(part)) inherited = 32
          }
        } else if (!depth) inherited = 0
        value = substr(value, consumed)
      }
      return output segment(value, inherited)
    }
    BEGIN { esc = sprintf("%c", 27); first = 1 }
    {
      if (lines == 2) {
        if (!first) printf "%s\n", render(pending)
        pending = $0
        first = 0
        next
      }
      if (!lines && !first) printf "\n"
      printf "%s", render($0)
      if (lines) printf "\n"
      first = 0
    }
    END {
      if (lines == 2 && !first) {
        sub(sprintf("%c", 1) "$", "", pending)
        printf "%s", render(pending)
      }
    }
  '
}
# read 的命令替换会使 stdout 成为管道，按输入与提示所在 stderr 判断终端。
jobs_prompt_render() {
  local jobs_prompt_color=0
  if [ -t 0 ] && [ -t 2 ] && jobs_prompt_color_ready; then jobs_prompt_color=1; fi
  printf "%s" "$1" | jobs_prompt_format "$jobs_prompt_color" 0
}
# 仅放在显示链末端；tee 在此函数之前接收纯文本，不把 ANSI 写入日志。
jobs_prompt_stream() {
  local jobs_prompt_color=0
  if [ -t 1 ] && jobs_prompt_color_ready; then jobs_prompt_color=1; fi
  jobs_prompt_format "$jobs_prompt_color" 1 1
}
# 显示管道保留原末尾换行；只删除本轮追加的最后一个结束标记。
jobs_prompt_filter() {
  local jobs_prompt_color=0
  if [ -t 1 ] && jobs_prompt_color_ready; then jobs_prompt_color=1; fi
  { /bin/cat; printf '\001'; } | jobs_prompt_format "$jobs_prompt_color" 2 1
}
# 仅包装原 printf/echo/print 展示，原参数、尾换行与显示命令退出码保持不变。
jobs_prompt_output() {
  local jobs_prompt_status=0 jobs_prompt_stderr=0 jobs_prompt_arg="" jobs_prompt_previous=""
  if [ "${1:-}" = print ]; then
    for jobs_prompt_arg in "$@"; do
      case "$jobs_prompt_arg" in -?*u2*|-u2) jobs_prompt_stderr=1 ;; esac
      if [ "$jobs_prompt_previous" = -u ] && [ "$jobs_prompt_arg" = 2 ]; then jobs_prompt_stderr=1; fi
      jobs_prompt_previous="$jobs_prompt_arg"
      [ "$jobs_prompt_arg" != -- ] || break
    done
  fi
  if [ -n "${ZSH_VERSION:-}" ]; then
    if [ "$jobs_prompt_stderr" = 1 ]; then
      "$@" 2>&1 | jobs_prompt_filter >&2
      jobs_prompt_status=$(( ${pipestatus[1]} != 0 ? ${pipestatus[1]} : ${pipestatus[2]} ))
    else
      "$@" | jobs_prompt_filter
      jobs_prompt_status=$(( ${pipestatus[1]} != 0 ? ${pipestatus[1]} : ${pipestatus[2]} ))
    fi
  elif [ -n "${BASH_VERSION:-}" ]; then
    "$@" | jobs_prompt_filter
    jobs_prompt_status=$(( ${PIPESTATUS[0]} != 0 ? ${PIPESTATUS[0]} : ${PIPESTATUS[1]} ))
  else
    "$@" | jobs_prompt_filter
    jobs_prompt_status=$?
  fi
  return "$jobs_prompt_status"
}
# 仅替换日志 primitive 的 tee：磁盘同步追加纯文，终端保留非选项原色。
jobs_prompt_tee() {
  local jobs_prompt_log="$1" jobs_prompt_line="" jobs_prompt_newline=0
  while :; do
    jobs_prompt_line=""
    if IFS= read -r jobs_prompt_line; then jobs_prompt_newline=1; else jobs_prompt_newline=0; [ -n "$jobs_prompt_line" ] || break; fi
    if [ "$jobs_prompt_newline" = 1 ]; then
      { printf '%s\n' "$jobs_prompt_line"; printf '\001'; } | jobs_prompt_format 0 2 >> "$jobs_prompt_log" || return $?
      printf '%s\n' "$jobs_prompt_line" | jobs_prompt_filter || return $?
    else
      { printf '%s' "$jobs_prompt_line"; printf '\001'; } | jobs_prompt_format 0 2 >> "$jobs_prompt_log" || return $?
      printf '%s' "$jobs_prompt_line" | jobs_prompt_filter || return $?
    fi
  done
}
# JOBS_INPUT_CHOICE_STYLE_END

show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】JobsSql.sh'
  print -r -- '核心用途：安装或升级 Homebrew MySQL，按需启动和交互登录。'
  print -r -- '影响范围：Homebrew、所选 MySQL 公式及服务；保留已有数据库与认证配置。'
  jobs_prompt_output print -r -- '运行策略：普通安装/升级回车跳过；危险动作必须精确输入 YES；Ctrl+C 取消。'
  print -r -- '日志位置：系统临时目录中的 【MacOS】JobsSql.log（阅读确认后才创建）。'
  print -r -- '============================================================================'
  [[ -t 0 ]] || { print -u2 -r -- '当前没有可交互输入，请在终端中重新运行。'; exit 1; }
  local answer=""
  jobs_prompt_output print -n -r -- '已了解用途与影响，按回车继续；Ctrl+C 取消：'
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
  jobs_prompt_output print -n -r -- "$1（直接回车跳过；输入任意字符后回车执行）："
  IFS= read -r answer || { log "⚠ 输入已结束，停止。"; exit 1; }
  [[ -n "$answer" ]]
}
# 危险动作只接受精确大写 YES，取消不落入后续操作。
confirm_yes() {
  local answer=""
  log "⚠ $1"
  jobs_prompt_output print -n -r -- '仅输入大写 YES 后回车执行；其它输入取消：'
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
    jobs_prompt_output print -n -r -- '输入本次操作的完整公式名称（回车取消）：'
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
  jobs_prompt_output print -u2 -r -- "2、其它输入或直接回车：选择用户目录 ${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}，不使用 sudo；有管理员权限也可选此路径。"
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

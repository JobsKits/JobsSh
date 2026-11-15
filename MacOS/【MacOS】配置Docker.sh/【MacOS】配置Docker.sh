#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】配置Docker.sh
# - 核心用途：检查 CLI 与当前 context 引擎，可选安装/升级 Docker Desktop。
# - 影响范围：可能安装/升级 Desktop 或打开应用；不会代替用户接受许可或修改镜像源。
# - 运行提示：先展示自述，回车继续；普通写操作回车跳过，Ctrl+C 或 EOF 取消。
# shell: zsh
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
    # 完整颜色帧有界重发；仅退出恢复容忍帧外回车和明确方向键。
    jobs_terminal_style_query() {
        jobs_style_query_key=$1
        jobs_style_reply=''
        jobs_style_query_buffer=''
        jobs_style_query_target_reply=''
        jobs_style_query_target_normalized=''
        jobs_style_query_target_rgb=''
        jobs_style_query_st="${jobs_style_esc}\\"
        jobs_style_query_stale_count=0
        jobs_style_query_phase=${2:-strict}
        jobs_style_query_cr=$(printf '\r')
        jobs_style_query_lf=$(printf '\n.')
        jobs_style_query_lf=${jobs_style_query_lf%.}
        jobs_style_query_failure='未收到目标颜色的完整答复（最多 3 次查询，每次约 2 秒）'
        for jobs_style_query_round in 1 2 3; do
            printf '\033]%s;?\007' "$jobs_style_query_key" > /dev/tty || {
                jobs_style_query_failure='无法向原终端发送配色查询'
                return 1
            }
            for jobs_style_attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
                # 哨兵保留末尾换行，不能把只有回车的键盘输入误当成无答复。
                jobs_style_piece=$(dd bs=256 count=1 2>/dev/null < /dev/tty; printf '.')
                jobs_style_piece=${jobs_style_piece%.}
                jobs_style_query_buffer=$jobs_style_query_buffer$jobs_style_piece
                while [ -n "$jobs_style_query_buffer" ]; do
                    # 仅退出恢复阶段允许帧外的明确控制键，普通文字仍然失败。
                    if [ "$jobs_style_query_phase" = cleanup ]; then
                        jobs_style_query_control_sequence=''
                        jobs_style_query_control_partial=0
                        case $jobs_style_query_buffer in
                            "$jobs_style_query_cr"*) jobs_style_query_control_sequence=$jobs_style_query_cr ;;
                            "$jobs_style_query_lf"*) jobs_style_query_control_sequence=$jobs_style_query_lf ;;
                        esac
                        if [ -z "$jobs_style_query_control_sequence" ]; then
                            for jobs_style_query_direction in A B C D; do
                                for jobs_style_query_control_candidate in \
                                    "${jobs_style_esc}[${jobs_style_query_direction}" \
                                    "${jobs_style_esc}O${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;2${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;3${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;4${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;5${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;6${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;7${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;8${jobs_style_query_direction}"; do
                                    case $jobs_style_query_buffer in
                                        "$jobs_style_query_control_candidate"*)
                                            jobs_style_query_control_sequence=$jobs_style_query_control_candidate
                                            break 2
                                            ;;
                                    esac
                                    case $jobs_style_query_control_candidate in
                                        "$jobs_style_query_buffer"*) jobs_style_query_control_partial=1 ;;
                                    esac
                                done
                            done
                        fi
                        if [ -n "$jobs_style_query_control_sequence" ]; then
                            jobs_style_cleanup_control_keys=$(( ${jobs_style_cleanup_control_keys:-0} + 1 ))
                            if [ "$jobs_style_cleanup_control_keys" -gt 64 ]; then
                                jobs_style_query_failure='退出恢复期间已识别控制键超过 64 个，已停止自动恢复'
                                return 1
                            fi
                            jobs_style_query_buffer=${jobs_style_query_buffer#"$jobs_style_query_control_sequence"}
                            continue
                        fi
                        if [ "$jobs_style_query_control_partial" = 1 ]; then
                            break
                        fi
                    fi
                    case $jobs_style_query_buffer in
                        "$jobs_style_esc"|"$jobs_style_esc]") break ;;
                        "$jobs_style_esc]"*) ;;
                        *) jobs_style_query_failure='收到非配色查询输入，已停止读取'; return 1 ;;
                    esac
                    jobs_style_query_head=''
                    jobs_style_query_terminator=''
                    case $jobs_style_query_buffer in
                        *"$jobs_style_bel"*)
                            jobs_style_query_head=${jobs_style_query_buffer%%"$jobs_style_bel"*}
                            jobs_style_query_terminator=$jobs_style_bel
                            ;;
                    esac
                    case $jobs_style_query_buffer in
                        *"$jobs_style_query_st"*)
                            jobs_style_query_st_head=${jobs_style_query_buffer%%"$jobs_style_query_st"*}
                            if [ -z "$jobs_style_query_terminator" ] ||
                               [ "${#jobs_style_query_st_head}" -lt "${#jobs_style_query_head}" ]; then
                                jobs_style_query_head=$jobs_style_query_st_head
                                jobs_style_query_terminator=$jobs_style_query_st
                            fi
                            ;;
                    esac
                    [ -n "$jobs_style_query_terminator" ] || break
                    jobs_style_query_frame=$jobs_style_query_head$jobs_style_query_terminator
                    jobs_style_query_buffer=${jobs_style_query_buffer#"$jobs_style_query_frame"}
                    jobs_style_query_body=${jobs_style_query_head#"$jobs_style_esc]"}
                    case $jobs_style_query_body in
                        *';rgb:'*) ;;
                        *) jobs_style_query_failure='配色答复格式或 RGB 数据无效'; return 1 ;;
                    esac
                    jobs_style_query_frame_key=${jobs_style_query_body%%';rgb:'*}
                    case $jobs_style_query_frame_key in
                        10|11|12|'4;'[0-9]|'4;1'[0-5]) ;;
                        *) jobs_style_query_failure='收到不属于本次颜色协议的答复'; return 1 ;;
                    esac
                    jobs_style_query_frame_rgb=${jobs_style_query_body#"$jobs_style_query_frame_key;rgb:"}
                    jobs_style_query_frame_normalized=$(printf '%s\n' "$jobs_style_query_frame_rgb" | LC_ALL=C awk -F/ '
                        BEGIN { valid = 1 }
                        NR != 1 || NF != 3 { valid = 0; exit }
                        {
                            for (i = 1; i <= 3; i++) {
                                h = tolower($i)
                                if (length(h) < 1 || length(h) > 4 || h ~ /[^0-9a-f]/) {
                                    valid = 0
                                    exit
                                }
                                n = 0
                                for (j = 1; j <= length(h); j++) n = n * 16 + index("0123456789abcdef", substr(h, j, 1)) - 1
                                value[i] = int(n * 65535 / (16 ^ length(h) - 1) + 0.5)
                            }
                        }
                        END {
                            if (!valid || NR != 1) exit 1
                            printf "%d/%d/%d", value[1], value[2], value[3]
                        }
                    ')
                    if [ -z "$jobs_style_query_frame_normalized" ]; then
                        jobs_style_query_failure='配色答复格式或 RGB 数据无效'
                        return 1
                    fi
                    if [ "$jobs_style_query_frame_key" = "$jobs_style_query_key" ]; then
                        if [ -n "$jobs_style_query_target_reply" ] &&
                           [ "$jobs_style_query_target_normalized" != "$jobs_style_query_frame_normalized" ]; then
                            jobs_style_query_failure='同一颜色的重复答复不一致，已停止自动恢复'
                            return 1
                        fi
                        jobs_style_query_target_reply=$jobs_style_query_frame
                        jobs_style_query_target_normalized=$jobs_style_query_frame_normalized
                        jobs_style_query_target_rgb=$jobs_style_query_frame_rgb
                    else
                        jobs_style_query_stale_count=$((jobs_style_query_stale_count + 1))
                        if [ "$jobs_style_query_stale_count" -gt 128 ]; then
                            jobs_style_query_failure='收到过多旧颜色答复，已停止读取'
                            return 1
                        fi
                    fi
                done
                if [ -n "$jobs_style_query_target_reply" ] && [ -z "$jobs_style_query_buffer" ]; then
                    jobs_style_reply=$jobs_style_query_target_reply
                    jobs_style_normalized=$jobs_style_query_target_normalized
                    jobs_style_rgb=$jobs_style_query_target_rgb
                    return 0
                fi
            done
            # 残缺帧不能通过重发拼成另一个答复，更不能被当成键盘空输入。
            if [ -n "$jobs_style_query_buffer" ]; then
                jobs_style_query_failure='配色答复帧不完整，已停止自动恢复'
                return 1
            fi
        done
        return 1
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
            jobs_style_cleanup_issue='无法读取或设置原终端输入模式，或临时配色未完成核验'
            jobs_style_conflicts=''
            jobs_style_restore_safe=''
            jobs_style_cleanup_control_keys=0
            if [ "$jobs_style_applied_complete" = 1 ]; then
                jobs_style_stty=$(stty -g 2>/dev/null < /dev/tty) || jobs_style_stty=''
                if [ -n "$jobs_style_stty" ] && stty -echo -icanon min 0 time 1 2>/dev/null < /dev/tty; then
                    jobs_style_query_active=1
                    jobs_style_cleanup_ok=1
                    while IFS='|' read -r jobs_style_key jobs_style_expected jobs_style_original; do
                        [ -n "$jobs_style_key" ] || continue
                        if ! jobs_terminal_style_query "$jobs_style_key" cleanup; then
                            jobs_style_cleanup_ok=0
                            jobs_style_cleanup_issue="颜色项 $jobs_style_key：$jobs_style_query_failure"
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
                    stty "$jobs_style_stty" 2>/dev/null < /dev/tty || { jobs_style_cleanup_ok=0; jobs_style_cleanup_issue='无法恢复原终端输入模式'; }
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
                printf '终端配色未能安全自动恢复（%s）；确认覆盖当前配色后可运行：sh "%s"\n' "$jobs_style_cleanup_issue" "$jobs_style_recovery" >&2
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
    trap 'jobs_style_exit_status=129; jobs_terminal_style_cleanup 129 continue; jobs_style_changed=0; exit 129' HUP
    trap 'jobs_style_exit_status=130; jobs_terminal_style_cleanup 130 continue; jobs_style_changed=0; exit 130' INT
    trap 'jobs_style_exit_status=143; jobs_terminal_style_cleanup 143 continue; jobs_style_changed=0; exit 143' TERM
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
        trap 'jobs_style_exit_status=129; jobs_terminal_style_cleanup 129 continue; jobs_style_changed=0; exit 129' HUP
        trap 'jobs_style_exit_status=130; jobs_terminal_style_cleanup 130 continue; jobs_style_changed=0; exit 130' INT
        trap 'jobs_style_exit_status=143; jobs_terminal_style_cleanup 143 continue; jobs_style_changed=0; exit 143' TERM
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

SCRIPT_SOURCE="${(%):-%x}"
# 在任何写入前说明用途与风险，并阻止无交互运行。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】配置Docker.sh'
  print -r -- '核心用途：检查 CLI 与当前 context 引擎，可选安装/升级 Docker Desktop。'
  print -r -- '影响范围：可能安装/升级 Desktop 或打开应用；不会代替用户接受许可或修改镜像源。'
  jobs_prompt_output print -r -- '运行策略：安装/升级直接回车跳过，输入任意字符执行；持久配置或清理需 YES。'
  print -r -- '取消方式：Ctrl+C 或输入结束立即停止；确认前不会写日志或执行安装。'
  print -r -- "脚本位置：${SCRIPT_SOURCE:A}"
  print -r -- "日志位置：${TMPDIR:-/tmp}/${${${SCRIPT_SOURCE:A}:t}%.*}.log"
  print -r -- '============================================================================'
  [[ -t 0 ]] || { print -u2 -r -- '✖ 没有可交互输入，请在终端中使用 zsh 运行。'; exit 1; }
  read -r "?$(jobs_prompt_render '👉 已了解用途与影响，按回车继续；Ctrl+C 取消：')" _ || exit 1
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
  jobs_prompt_output print -n -r -- "$1（直接回车跳过；输入任意字符后回车执行）："
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
  jobs_prompt_output log "⚠ Homebrew 缺失或损坏，输入 YES 选择系统目录 $system_prefix；其它输入或回车选择 ${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}。"
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
# 发现 Docker Desktop 的实际位置及健康 CLI，兼容用户安装目录。
find_docker_runtime() {
  local candidate docker_candidate
  DOCKER_APP=""
  DOCKER_BIN=""
  for candidate in "${JOBS_DOCKER_APPDIR:-$HOME/Applications}/Docker.app" "$HOME/Applications/Docker.app" /Applications/Docker.app; do
    [[ -d "$candidate" ]] || continue
    DOCKER_APP="$candidate"
    break
  done
  for docker_candidate in "$(command -v docker 2>/dev/null)" "$HOME/.docker/bin/docker" "${DOCKER_APP:+$DOCKER_APP/Contents/Resources/bin/docker}"; do
    [[ -n "$docker_candidate" && -x "$docker_candidate" ]] || continue
    if "$docker_candidate" --version >/dev/null 2>&1; then
      DOCKER_BIN="$docker_candidate"
      return 0
    fi
  done
  return 1
}
# 使用当前官方 Cask 管理 Desktop，已有其它 Docker 环境可以直接复用。
manage_docker_desktop() {
  local appdir="${JOBS_DOCKER_APPDIR:-$HOME/Applications}" action=install
  find_docker_runtime || log '⚠ 未找到健康 Docker CLI。'
  [[ -z "$DOCKER_BIN" ]] || run_logged "$DOCKER_BIN" --version || fail 'Docker CLI 版本检查失败。'
  if ! ask_any_to_run '是否通过 Homebrew 安装或升级 Docker Desktop？'; then
    return 0
  fi
  jobs_brew_install_or_exit
  if [[ -n "$DOCKER_APP" ]]; then
    appdir="${DOCKER_APP:h}"
    if "$JOBS_HOMEBREW_BIN" list --cask --versions docker-desktop >/dev/null 2>&1; then
      action=upgrade
    else
      fail "检测到非 Homebrew 管理的 Desktop：$DOCKER_APP；请在应用内升级，未覆盖。"
    fi
  fi
  [[ "$appdir" == /* && "$appdir" != / && "$appdir" != *$'\n'* ]] || fail 'Docker 应用目录必须是有效绝对路径。'
  appdir="${appdir:A}"
  if [[ "$appdir" != "$HOME/"* ]]; then
    confirm_yes "目标应用目录位于用户主目录之外：$appdir；安装器可能请求管理员权限。" || return 0
  fi
  show_source "$action" Docker-Desktop "${HOMEBREW_API_DOMAIN:-https://formulae.brew.sh/api}/cask/docker-desktop.json；安装包地址由 Homebrew 解析" "$appdir/Docker.app"
  log '官方说明：https://docs.docker.com/desktop/setup/install/mac-install/'
  if [[ "$appdir" == "$HOME/"* ]]; then
    run_logged env HOMEBREW_NO_SUDO=1 "$JOBS_HOMEBREW_BIN" "$action" --cask --no-binaries "--appdir=$appdir" docker-desktop || fail 'Docker Desktop 用户目录安装/升级失败。'
  else
    run_logged "$JOBS_HOMEBREW_BIN" "$action" --cask "--appdir=$appdir" docker-desktop || fail 'Docker Desktop 安装/升级失败。'
  fi
  JOBS_DOCKER_APPDIR="$appdir"
  find_docker_runtime || fail "安装后 CLI 复检失败：$appdir/Docker.app"
  log "✔ Desktop 文件与 CLI 已就绪：$DOCKER_APP；引擎状态尚未验证。"
}
# 对当前 Docker context 的引擎检查设置截止时间，避免远端连接无限等待。
check_docker_engine() {
  local output pid result=0 count=0 limit="${JOBS_DOCKER_CHECK_SECONDS:-15}"
  [[ "$limit" == <-> && "$limit" -ge 1 && "$limit" -le 60 ]] || fail 'JOBS_DOCKER_CHECK_SECONDS 必须是 1 至 60 的整数。'
  output="$(mktemp "${TMPDIR:-/tmp}/jobs-docker-info.XXXXXX")" || return 1
  "$DOCKER_BIN" info --format '{{.ServerVersion}}' > "$output" 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if (( count >= limit )); then
      kill -TERM "$pid" 2>/dev/null
      sleep 1
      kill -KILL "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      cat "$output" | sanitize_stream | tee -a "$LOG_FILE"
      rm -- "$output"
      log "⚠ 引擎检查超过 ${limit} 秒，当前 context 尚未验证可用。"
      return 1
    fi
    sleep 1
    (( count += 1 ))
  done
  wait "$pid" || result=$?
  cat "$output" | sanitize_stream | tee -a "$LOG_FILE"
  rm -- "$output"
  (( result == 0 ))
}
# 可选打开 Desktop，保留许可、context 和镜像配置由用户管理。
verify_docker_runtime() {
  if [[ -z "$DOCKER_BIN" ]]; then
    log 'ℹ 未选择安装且没有健康 CLI，本次未进行引擎验证。'
    return 0
  fi
  if check_docker_engine; then
    log '✔ 当前 Docker context 的引擎可连接。'
    return 0
  fi
  log '⚠ CLI 可用，但当前 context 的引擎尚未就绪；没有修改 context、代理或镜像源。'
  if [[ -n "$DOCKER_APP" ]] && ask_any_to_run "是否打开 $DOCKER_APP 并再次检查？首次启动需在应用内确认许可。"; then
    run_logged open "$DOCKER_APP" || fail '无法打开 Docker Desktop。'
    check_docker_engine || fail 'Docker 引擎仍未就绪；请完成应用首次设置或检查当前 context 后重试。'
    log '✔ 当前 Docker context 的引擎可连接。'
  else
    fail 'Docker 引擎检查失败，未报告安装配置成功。'
  fi
}
# 编排确认、运行准备和各项业务步骤。
main() {
  show_script_intro_and_wait # 首先展示内置自述，确认前不产生写入。
  initialize_script_runtime # 确认后初始化路径、日志和纯文本命令输出。
  manage_docker_desktop # 复用现有 CLI 或按选择管理 Desktop。
  verify_docker_runtime # 分别验证 CLI 与当前 context 的引擎。
  report_completion # 输出所选步骤的结束位置与日志。
}

main "$@"

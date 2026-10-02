#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】HEIC2Jpg.sh
# - 核心用途：执行“HEIC2Jpg”对应的自动化任务。
# - 影响范围：可能修改当前项目、用户环境或脚本指定的目标。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】HEIC2Jpg.sh'
  print -r -- '核心用途：执行“HEIC2Jpg”对应的自动化任务。'
  print -r -- '影响范围：可能修改当前项目、用户环境或脚本指定的目标。'
  print -r -- '取消方式：确认前按 Ctrl+C 终止，不会继续执行后续业务。'
  print -r -- '============================================================================'
  if [[ ! -t 0 ]]; then
    print -u2 -r -- '当前没有可交互输入，请在终端中重新运行。'
    exit 1
  fi
  read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" _ || exit 1
}
# 执行入口下沉后的完整业务流程和控制逻辑。
run_main_business_flow() {
# 需要在桌面建立一个2的文件夹（里面是）*.heic
mkdir -p /Users/jobs/Desktop/3
find /Users/jobs/Desktop/2 -maxdepth 1 -iname "*.heic" | while read file; do
  filename=$(basename "$file")
  filename_no_ext="${filename%.*}"
  # 执行当前流程中的独立业务步骤：sips。
  sips -s format jpeg "$file" --out /Users/jobs/Desktop/3/"$filename_no_ext".jpg
done
}
# 初始化 zsh 通配符策略。
initialize_script_runtime() {
  setopt NO_NOMATCH TYPESET_SILENT
}
# 编排脚本的高层业务流程。
main() {
  show_script_intro_and_wait # 展示脚本内置自述，并按运行入口完成防误触确认。
  initialize_script_runtime # 确认后初始化 zsh 运行选项。
  run_main_business_flow "$@" # 执行入口下沉后的完整业务流程。
}

main "$@"

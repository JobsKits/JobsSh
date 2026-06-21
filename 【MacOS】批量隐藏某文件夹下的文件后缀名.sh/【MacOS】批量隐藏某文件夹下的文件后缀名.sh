#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】批量隐藏某文件夹下的文件后缀名.sh
# - 核心用途：执行“批量隐藏某文件夹下的文件后缀名”对应的自动化任务。
# - 影响范围：可能修改当前项目、用户环境或脚本指定的目标。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】批量隐藏某文件夹下的文件后缀名.sh'
  print -r -- '核心用途：执行“批量隐藏某文件夹下的文件后缀名”对应的自动化任务。'
  print -r -- '影响范围：可能修改当前项目、用户环境或脚本指定的目标。'
  print -r -- '取消方式：确认前按 Ctrl+C 终止，不会继续执行后续业务。'
  print -r -- '============================================================================'
  if [[ ! -t 0 ]]; then
    print -u2 -r -- '当前没有可交互输入，请在终端中重新运行。'
    return 1
  fi
  read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" _
}
# 执行入口下沉后的完整业务流程和控制逻辑。
run_main_business_flow() {
# 提示用户输入路径
read "?📁 请输入要处理的文件夹路径: " TARGET_DIR

# 检查 SetFile 是否可用
if ! command -v SetFile &> /dev/null; then
  # 输出当前步骤的提示或执行进度。
  echo "⚠️ 未找到 SetFile 命令，请先安装：xcode-select --install"
  # 执行当前流程中的独立业务步骤：exit。
  exit 1
fi

# 检查路径有效性
if [[ ! -d "$TARGET_DIR" ]]; then
  # 输出当前步骤的提示或执行进度。
  echo "❌ 路径无效：$TARGET_DIR"
  # 执行当前流程中的独立业务步骤：exit。
  exit 1
fi

# 递归查找所有普通文件
find "$TARGET_DIR" -type f | while read -r file; do
  # 执行当前流程中的独立业务步骤：SetFile。
  SetFile -a E "$file"
  # 输出当前步骤的提示或执行进度。
  echo "✅ 隐藏扩展名：$file"
done

# 输出当前步骤的提示或执行进度。
echo "🎉 完成：已隐藏 $TARGET_DIR 及其所有子目录下的文件扩展名"
}
# 编排脚本的高层业务流程。
main() {
  # 展示脚本内置自述，并按运行入口完成防误触确认。
  show_script_intro_and_wait
  # 执行入口下沉后的完整业务流程。
  run_main_business_flow "$@"
}

main "$@"

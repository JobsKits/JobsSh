#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】下载网页中无法下载的视频.sh
# - 核心用途：执行“下载网页中无法下载的视频”对应的自动化任务。
# - 影响范围：可能修改当前项目、用户环境或脚本指定的目标。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】下载网页中无法下载的视频.sh'
  print -r -- '核心用途：执行“下载网页中无法下载的视频”对应的自动化任务。'
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
# 检查安装 brew
if ! command -v brew &> /dev/null
then
    # 输出当前步骤的提示或执行进度。
    echo "brew 未安装，开始安装..."
    # 执行当前流程中的独立业务步骤：open。
    open https://brew.sh/
    # 执行当前流程中的独立业务步骤：处理当前语句。
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ## brew环境变量设置
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/$(whoami)/.zprofile
    # 执行当前流程中的独立业务步骤：open。
    open /Users/$(whoami)/.zprofile
    # 执行当前流程中的独立业务步骤：eval。
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # 输出当前步骤的提示或执行进度。
    echo "brew 已经安装，跳过安装步骤。"
    ## brew 升级
    brew update
    # 执行当前流程中的独立业务步骤：brew。
    brew doctor
    # 执行当前流程中的独立业务步骤：brew。
    brew -v
fi
# 检查安装 you-get
if [[ $(command -v you-get) ]]; then
  # 输出当前步骤的提示或执行进度。
  echo "you-get is already installed."
else
  # 输出当前步骤的提示或执行进度。
  echo "you-get is not installed. Installing..."
  # https://you-get.org/
  brew install you-get
fi

# 收集用户输入，供后续业务判断使用。
read "?请输入视频源,以回车结束:" videoSource
# 执行当前流程中的独立业务步骤：You。
You-get $videoSource
}
# 编排脚本的高层业务流程。
main() {
  show_script_intro_and_wait # 展示脚本内置自述，并按运行入口完成防误触确认。
  run_main_business_flow "$@" # 执行入口下沉后的完整业务流程。
}

main "$@"

#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】关于Gem.sh
# - 核心用途：执行“关于Gem”对应的自动化任务。
# - 影响范围：可能修改当前项目、用户环境或脚本指定的目标。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 输出当前 RubyGems 的软件源列表。
show_gem_sources() {
  echo "Mac OS 自带Gem"
  echo "列出安装源"
  gem sources -l
}
# 将 RubyGems 软件源切换到国内镜像并刷新缓存。
configure_gem_source() {
  gem sources --remove https://rubygems.org/
  gem sources --add https://gems.ruby-china.com/
  echo "更新安装源缓存"
  gem sources -u
}
# 更新 RubyGems 本体及已安装程序包，并清理旧缓存。
update_gem_environment() {
  echo "更新Gem本身"
  gem update --system
  echo "查看下目前的Gem的版本"
  gem -v
  echo "更新所有程序包"
  gem update
  echo "清理gem"
  gem clean
}
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】关于Gem.sh'
  print -r -- '核心用途：执行“关于Gem”对应的自动化任务。'
  print -r -- '影响范围：可能修改当前项目、用户环境或脚本指定的目标。'
  print -r -- '取消方式：确认前按 Ctrl+C 终止，不会继续执行后续业务。'
  print -r -- '============================================================================'
  if [[ ! -t 0 ]]; then
    print -u2 -r -- '当前没有可交互输入，请在终端中重新运行。'
    return 1
  fi
  read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" _
}
# 编排脚本的高层业务流程。
# 初始化脚本运行环境，并集中承载原有的顶层执行逻辑。
initialize_script_runtime() {
  setopt NO_NOMATCH
}
# 编排脚本的高层业务流程。
main() {
  # 展示脚本内置自述，并按运行入口完成防误触确认。
  show_script_intro_and_wait
  # 初始化 Shell 选项、日志、依赖和入口运行状态。
  initialize_script_runtime
  # 执行 show_gem_sources 对应的独立业务步骤。
  show_gem_sources
  # 执行 configure_gem_source 对应的独立业务步骤。
  configure_gem_source
  # 执行 update_gem_environment 对应的核心业务步骤。
  update_gem_environment
}

main "$@"

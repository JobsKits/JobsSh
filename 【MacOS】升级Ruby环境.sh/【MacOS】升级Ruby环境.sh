#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】升级Ruby环境.sh
# - 核心用途：执行“升级Ruby环境”对应的本机环境配置任务。
# - 影响范围：可能安装、更新或修改当前用户的工具链与配置文件。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】升级Ruby环境.sh'
  print -r -- '核心用途：执行“升级Ruby环境”对应的本机环境配置任务。'
  print -r -- '影响范围：可能安装、更新或修改当前用户的工具链与配置文件。'
  print -r -- '取消方式：确认前按 Ctrl+C 终止，不会继续执行后续业务。'
  print -r -- '============================================================================'
  if [[ ! -t 0 ]]; then
    print -u2 -r -- '当前没有可交互输入，请在终端中重新运行。'
    exit 1
  fi
  read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" _ || exit 1
}
# 执行入口下沉后的完整业务流程和控制逻辑。
# 如果没有执行权限，在这个sh文件的目录下，执行chmod u+x *.sh
# 检查当前Ruby环境
check_ruby_environment() {
    # 输出当前步骤的提示或执行进度。
    echo "检查使用的是否是系统自带的 Ruby 还是我们自定义的 Ruby 环境"
    # 输出当前步骤的提示或执行进度。
    echo "查看本机的 Ruby 环境安装目录"
    # 执行当前流程中的独立业务步骤：which。
    which -a ruby
    # 输出当前步骤的提示或执行进度。
    echo "如果您使用的是 Mac OS 系统自带的 Ruby 环境，OS X将回应： /usr/bin/ruby"
    # 输出当前步骤的提示或执行进度。
    echo "如果您使用的是 Gem 环境安装的 Ruby 环境，OS X将回应： /usr/local/opt/ruby/bin/ruby"
}
# 设置 Ruby 环境变量（检查要被写入的文件里面是否存在定义，防止重复添加）
setup_ruby_environment() {
    local ruby_path="/usr/local/opt/ruby/bin"

    # 检查 ~/.bash_profile 是否已经包含了相同路径
    if ! grep -qE "^\s*export PATH=\"$ruby_path:\$PATH\"" ~/.bash_profile; then
        echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.bash_profile
        source ~/.bash_profile
    fi
    
    # 检查 ~/.zshrc 是否已经包含了相同路径
    if ! grep -qE "^\s*export PATH=\"$ruby_path:\$PATH\"" ~/.zshrc; then
        echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
        source ~/.zshrc
    fi

    # 打开 ~/.bash_profile 和 ~/.zshrc
    open ~/.bash_profile
    open ~/.zshrc
}
# 检查 macOS 系统自带的 Ruby 环境
check_system_ruby() {
    if command -v ruby >/dev/null 2>&1; then
        echo "系统自带的 Ruby 环境存在"
        return 0
    else
        echo "系统自带的 Ruby 环境不存在"
        return 1
    fi
}
# 检查 Brew 安装的 Ruby 环境
check_brew_ruby() {
    if command -v brew >/dev/null 2>&1 && brew list ruby >/dev/null 2>&1; then
        echo "通过 Brew 安装的 Ruby 环境存在"
        return 0
    else
        echo "通过 Brew 安装的 Ruby 环境不存在"
        return 1
    fi
}
# 检查 Rbenv 安装的 Ruby 环境
check_rbenv_ruby() {
    if command -v rbenv >/dev/null 2>&1 && rbenv versions | grep -q "system"; then
        echo "通过 Rbenv 安装的 Ruby 环境存在"
        return 0
    else
        echo "通过 Rbenv 安装的 Ruby 环境不存在"
        return 1
    fi
}
# 升级系统当前使用的 Ruby 环境
upgrade_ruby() {
    if check_system_ruby; then
        echo "正在升级系统自带的 Ruby 环境..."
        sudo gem update --system
        echo "系统自带的 Ruby 环境已升级完成"
    elif check_brew_ruby; then
        echo "正在升级通过 Brew 安装的 Ruby 环境..."
        brew update
        brew upgrade ruby
        brew cleanup ruby
        echo "通过 Brew 安装的 Ruby 环境已升级完成"
    elif check_rbenv_ruby; then
        echo "正在升级通过 Rbenv 安装的 Ruby 环境..."
        rbenv install --list | grep -v - | tail -1 | xargs -I {} rbenv install {}
        rbenv global $(rbenv versions --bare | grep -v - | tail -1)
        echo "通过 Rbenv 安装的 Ruby 环境已升级完成"
    else
        echo "未找到可用的 Ruby 环境"
    fi
}
# 检查并升级 Ruby 环境
# 编排脚本的高层业务流程。
# 初始化脚本运行环境，并集中承载原有的顶层执行逻辑。
run_main_business_flow() {
  upgrade_ruby
}
# 初始化 zsh 通配符策略。
initialize_script_runtime() {
  setopt NO_NOMATCH TYPESET_SILENT
}
# 编排脚本的高层业务流程。
main() {
  show_script_intro_and_wait # 展示脚本内置自述，并按运行入口完成防误触确认。
  initialize_script_runtime # 确认后初始化 zsh 运行选项。
  run_main_business_flow "$@" # 执行脚本原有的完整业务流程。
}
main "$@"

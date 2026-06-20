#!/bin/zsh

setopt NO_NOMATCH

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

# 编排 RubyGems 软件源配置与升级流程。
run_main_flow() {
  show_gem_sources
  configure_gem_source
  update_gem_environment
}

# 统一收口脚本入口，仅委托已经拆分完成的业务流程。
main() {
  # 调用 RubyGems 配置与升级流程：主入口不直接承载具体命令。
  run_main_flow "$@"
}

main "$@"

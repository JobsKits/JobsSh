#! /bin/sh

# 收拢旧脚本原有执行顺序，后续复杂职责可继续拆分。
run_main_flow() {

# Mac下安装配置Tomcat https://zhuanlan.zhihu.com/p/35775446

# 如果没有执行权限，在这个sh文件的目录下，执行chmod u+x *.sh

echo "Mac OS 本地自带一个Tomcat，对此进行启动"
sudo apachectl start
}

# 统一收口脚本入口，仅委托已经拆分完成的业务流程。
main() {
  # 主入口只负责委托完整业务流程，复杂逻辑统一下沉。
  run_main_flow "$@"
}

main "$@"

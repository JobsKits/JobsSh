#! /bin/sh

# 收拢旧脚本原有执行顺序，后续复杂职责可继续拆分。
run_main_flow() {

open -a "/Applications/Safari.app" https://docs.docker.com/desktop/mac/install/

brew install --cask --appdir=/Applications docker
# 镜像加速 http://hub-mirror.c.163.com
# 在任务栏点击 Docker for mac 应用图标
## -> Perferences...
## -> Daemon
## -> Registry mirrors
# 在列表中填写加速器地址即可
# 修改完成之后，点击 Apply & Restart 按钮，Docker 就会重启并应用配置的镜像地址了
docker --version
# 查看是否配置成功
docker info
}

# 统一收口脚本入口，仅委托已经拆分完成的业务流程。
main() {
  # 主入口只负责委托完整业务流程，复杂逻辑统一下沉。
  run_main_flow "$@"
}

main "$@"

#!/bin/bash
# 脚本自述：
# - 脚本名称：【MacOS】完全删除以brew方式安装的Mysql.sh
# - 核心用途：执行“完全删除以brew方式安装的Mysql”对应的本机环境配置任务。
# - 影响范围：可能安装、更新或修改当前用户的工具链与配置文件。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】完全删除以brew方式安装的Mysql.sh'
  print -r -- '核心用途：执行“完全删除以brew方式安装的Mysql”对应的本机环境配置任务。'
  print -r -- '影响范围：可能安装、更新或修改当前用户的工具链与配置文件。'
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
# 输出当前步骤的提示或执行进度。
echo '关闭本机通过 brew 方式安装的 MySql 服务'
# 执行当前流程中的独立业务步骤：brew。
brew services stop mysql
# 执行当前流程中的独立业务步骤：mysql。
mysql.server stop
# 输出当前步骤的提示或执行进度。
echo '彻底删除本机通过 brew 方式安装的 MySql'
# 执行当前流程中的独立业务步骤：brew。
brew uninstall mysql
# brew cleanup

# 执行当前流程中的独立业务步骤：open。
open /opt/homebrew/var/mysql
# 收集用户输入，供后续业务判断使用。
read -p "是否删除本地 mysql 的 database？回车删除，其他任意字符不删除" delMysqlDB
# 根据当前条件选择对应的执行分支。
if [[ $delMysqlDB = "" ]];then
    # 初始化当前流程后续步骤需要使用的变量。
    mySqlDBPATH=$"/opt/homebrew/var/mysql"
    # 执行当前流程中的独立业务步骤：rm。
    rm -r $mySqlDBPATH
fi

}
# 编排脚本的高层业务流程。
main() {
  # 展示脚本内置自述，并按运行入口完成防误触确认。
  show_script_intro_and_wait
  # 执行入口下沉后的完整业务流程。
  run_main_business_flow "$@"
}

main "$@"

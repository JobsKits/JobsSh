#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh
# - 核心用途：执行“修改Mysql的配置文件：my.cnf【修改后再运行】”对应的本机环境配置任务。
# - 影响范围：可能安装、更新或修改当前用户的工具链与配置文件。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】修改Mysql的配置文件：my.cnf【修改后再运行】.sh'
  print -r -- '核心用途：执行“修改Mysql的配置文件：my.cnf【修改后再运行】”对应的本机环境配置任务。'
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
run_main_business_flow() {
# !/bin/bash

# 输出当前步骤的提示或执行进度。
echo '关闭本机通过 brew 方式安装的 MySql 服务'
# 执行当前流程中的独立业务步骤：brew。
brew services stop mysql
# 执行当前流程中的独立业务步骤：mysql。
mysql.server stop

# 输出当前步骤的提示或执行进度。
echo '本机通过 brew 形式安装的 MySql 安装目录'
# 执行当前流程中的独立业务步骤：brew。
brew list mysql
# 不出意外，会对外输出 /opt/homebrew/Cellar/mysql
mysql --version

# 字符串截取 mysql 的版本号
mysqlVersion=$(mysql --version | awk -F 'Ver ' '{ print $2 }' | awk -F ' for' '{ print $1 }')
fileCopy_fullname=$"/opt/homebrew/Cellar/mysql/"${mysqlVersion}"/.bottle/etc/my.cnf"
# 输出当前步骤的提示或执行进度。
echo "fileCopy_fullname:"$fileCopy_fullname

# 直接追加写入
cat>>${fileCopy_fullname}<<EOF
# 这里写入需要修改的配置信息
gtid_mode=ON  
log-slave-updates=1  
enforce-gtid-consistency=1  
# skip-grant-tables // 放开这句，Mysql 的端口将为 0。且强行定义端口都始终为0

EOF

# 执行当前流程中的独立业务步骤：code。
code $fileCopy_fullname
# 收集用户输入，供后续业务判断使用。
read "?检查完毕并保存:通过brew管理的Mysql配置文件【my.cnf】" _
# 执行当前流程中的独立业务步骤：sudo。
sudo cp $fileCopy_fullname /etc/my.cnf
# 执行当前流程中的独立业务步骤：code。
code /etc/my.cnf
# 执行当前流程中的独立业务步骤：brew。
brew services restart mysql 

# 输出当前步骤的提示或执行进度。
echo "不需要验证密码，直接登录 mysql"
# 执行当前流程中的独立业务步骤：mysql。
mysql -p
}
# 编排脚本的高层业务流程。
main() {
  show_script_intro_and_wait # 展示脚本内置自述，并按运行入口完成防误触确认。
  run_main_business_flow "$@" # 执行入口下沉后的完整业务流程。
}

main "$@"

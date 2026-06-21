#!/bin/bash
# 脚本自述：
# - 脚本名称：【MacOS】删除brew-MySql数据库并重置密码为空.sh
# - 核心用途：执行“删除brew-MySql数据库并重置密码为空”对应的清理任务。
# - 影响范围：可能删除缓存、生成物、配置记录或解除已有跟踪关系。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】删除brew-MySql数据库并重置密码为空.sh'
  print -r -- '核心用途：执行“删除brew-MySql数据库并重置密码为空”对应的清理任务。'
  print -r -- '影响范围：可能删除缓存、生成物、配置记录或解除已有跟踪关系。'
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

# 输出当前步骤的提示或执行进度。
echo '本机重新通过 brew 形式安装 MySql'
# 执行当前流程中的独立业务步骤：brew。
brew install mysql
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

# 执行当前流程中的独立业务步骤：grep。
grep skip-grant-tables $fileCopy_fullname
# 根据当前条件选择对应的执行分支。
if [ $? -ne 0 ] ;then
# 执行当前流程中的独立业务步骤：cat。
cat>>${fileCopy_fullname}<<EOF
# skip-grant-tables // 放开这句，Mysql 的端口将为 0。且强行定义端口都始终为0
EOF
fi

# 执行当前流程中的独立业务步骤：code。
code $fileCopy_fullname
# 执行当前流程中的独立业务步骤：sudo。
sudo cp $fileCopy_fullname /etc/my.cnf
# 执行当前流程中的独立业务步骤：code。
code /etc/my.cnf
# 执行当前流程中的独立业务步骤：brew。
brew services restart mysql
}
# 编排脚本的高层业务流程。
main() {
  # 展示脚本内置自述，并按运行入口完成防误触确认。
  show_script_intro_and_wait
  # 执行入口下沉后的完整业务流程。
  run_main_business_flow "$@"
}

main "$@"

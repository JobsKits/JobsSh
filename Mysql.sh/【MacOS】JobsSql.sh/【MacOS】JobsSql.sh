#!/bin/bash
# 脚本自述：
# - 脚本名称：【MacOS】JobsSql.sh
# - 核心用途：执行“JobsSql”对应的自动化任务。
# - 影响范围：可能修改当前项目、用户环境或脚本指定的目标。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】JobsSql.sh'
  print -r -- '核心用途：执行“JobsSql”对应的自动化任务。'
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
# 如果没有执行权限，在这个sh文件的目录下，执行chmod u+x *.sh
filePath=$(dirname $0)/$(basename $0)
# 输出当前步骤的提示或执行进度。
echo "我在这里：$filePath" 

# 定位📌于该文件的垂直文件夹
folderPath=$(dirname $0)
# 执行当前流程中的独立业务步骤：cd。
cd folderPath
# 加权限
fileFullName=$(basename $0)
# 执行当前流程中的独立业务步骤：chmod。
chmod u+x $fileFullName

# 输出当前步骤的提示或执行进度。
echo "先关闭mysql的服务"
# 执行当前流程中的独立业务步骤：brew。
brew services stop mysql
# 收集用户输入，供后续业务判断使用。
read -p "是否先清理后安装brew_mysql?回车跳过:" cleanUp
# 输入非回车，进行清理安装
if [[ $cleanUp -ne "" ]];then
    # 执行当前流程中的独立业务步骤：brew。
    brew uninstall mysql
    # 执行当前流程中的独立业务步骤：brew。
    brew cleanup
fi

# 输出当前步骤的提示或执行进度。
echo "通过brew安装mysql"
# 执行当前流程中的独立业务步骤：brew。
brew install mysql

# 输出当前步骤的提示或执行进度。
echo "mysql的安装信息"
# 执行当前流程中的独立业务步骤：brew。
brew info mysql

# 输出当前步骤的提示或执行进度。
echo "查询本机的MySql的安装路径"
# 执行当前流程中的独立业务步骤：whereis。
whereis mysql

# 输出当前步骤的提示或执行进度。
echo "查询本机的MySql的安装目录"
# 执行当前流程中的独立业务步骤：brew。
brew list mysql

# 定位📌到brew_mysql的根目录
cd /opt/homebrew/Cellar/mysql/8.0.32

# 没有才添加，有就不加
grep skip-grant-tables .bottle/etc/my.cnf
# 根据当前条件选择对应的执行分支。
if [ $? -ne 0 ] ;then
    # 编辑`.bottle/etc/my.cnf`，在其末尾增添一句话：`skip-grant-tables`
    echo "skip-grant-tables" >> .bottle/etc/my.cnf
fi

# 复制`.bottle/etc/my.cnf  `→ `/etc  `
cp /opt/homebrew/Cellar/mysql/8.0.32/.bottle/etc/my.cnf /etc  

# 重启mysql服务
mysql.server start

# 输出当前步骤的提示或执行进度。
echo "查询本机的MySql的PID"
# 执行当前流程中的独立业务步骤：lsof。
lsof -nP -i | grep mysql 

# 输出当前步骤的提示或执行进度。
echo "进入root用户（无密码）"
# 执行当前流程中的独立业务步骤：mysql。
mysql -uroot -p
}
# 编排脚本的高层业务流程。
main() {
  # 展示脚本内置自述，并按运行入口完成防误触确认。
  show_script_intro_and_wait
  # 执行入口下沉后的完整业务流程。
  run_main_business_flow "$@"
}

main "$@"

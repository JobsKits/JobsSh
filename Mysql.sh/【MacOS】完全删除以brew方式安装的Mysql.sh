#!/bin/bash

# 收拢旧脚本原有执行顺序，后续复杂职责可继续拆分。
run_main_flow() {

echo '关闭本机通过 brew 方式安装的 MySql 服务'
brew services stop mysql
mysql.server stop
echo '彻底删除本机通过 brew 方式安装的 MySql'
brew uninstall mysql
# brew cleanup

open /opt/homebrew/var/mysql
read -p "是否删除本地 mysql 的 database？回车删除，其他任意字符不删除" delMysqlDB
if [[ $delMysqlDB = "" ]];then
    mySqlDBPATH=$"/opt/homebrew/var/mysql"
    rm -r $mySqlDBPATH
fi

}

# 统一收口脚本入口，仅委托已经拆分完成的业务流程。
main() {
  # 主入口只负责委托完整业务流程，复杂逻辑统一下沉。
  run_main_flow "$@"
}

main "$@"

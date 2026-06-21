#!/bin/bash
# 脚本自述：
# - 脚本名称：【MacOS】PhpApacheConfig.sh
# - 核心用途：执行“PhpApacheConfig”对应的自动化任务。
# - 影响范围：可能修改当前项目、用户环境或脚本指定的目标。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】PhpApacheConfig.sh'
  print -r -- '核心用途：执行“PhpApacheConfig”对应的自动化任务。'
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
# 参考资料
## https://getgrav.org/blog/macos-monterey-apache-multiple-php-versions
## https://www.cnblogs.com/ice5/p/15783811.html

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

# 根据当前条件选择对应的执行分支。
if brew -v;then
    # 输出当前步骤的提示或执行进度。
    echo "The package is installed"
    # 执行当前流程中的独立业务步骤：brew。
    brew update
    # 执行当前流程中的独立业务步骤：brew。
    brew doctor
    # 执行当前流程中的独立业务步骤：brew。
    brew -v
else
    # 输出当前步骤的提示或执行进度。
    echo "The package is not installed"
    # 执行当前流程中的独立业务步骤：open。
    open https://brew.sh/
    # 执行当前流程中的独立业务步骤：处理当前语句。
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ### brew环境变量设置
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/$(whoami)/.zprofile
    # 执行当前流程中的独立业务步骤：eval。
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 执行当前流程中的独立业务步骤：brew。
brew install php
# 执行当前流程中的独立业务步骤：brew。
brew install openssl
# 执行当前流程中的独立业务步骤：brew。
brew install httpd
# 执行当前流程中的独立业务步骤：brew。
brew services start httpd
# 执行当前流程中的独立业务步骤：brew。
brew tap shivammathur/php

# 执行当前流程中的独立业务步骤：open。
open http://localhost:8080/


#sudo su //切到root帐号
#配置文件与网站根目录默认所在位置
#/etc/apache2/httpd.conf //配置文件
#/Library/WebServer/Documents //网站根目录

#sudo apachectl start // 开启Apache
#sudo apachectl stop // 关闭Apache
#sudo apachectl restart // 重启Apache


# 故障排除提示
## 如果您收到浏览器无法连接到服务器的消息,请首先检查以确保服务器已启动
ps -aef | grep httpd

## 如果 Apache 已启动并正在运行,您应该会看到一些 httpd 进程
## 尝试使用以下命令重新启动 Apache
brew services restart httpd

# 执行当前流程中的独立业务步骤：open。
open https://getgrav.org/blog/macos-monterey-apache-multiple-php-versions

# 输出当前步骤的提示或执行进度。
echo "在最新版本的 Brew 中,您必须手动将侦听端口从默认设置8080为80,因此我们需要编辑 Apache 的配置文件/opt/homebrew/etc/httpd/httpd.conf"
# 执行当前流程中的独立业务步骤：vim。
vim /opt/homebrew/etc/httpd/httpd.conf

# 执行当前流程中的独立业务步骤：Listen。
Listen 8080 更改为 Listen 80

}
# 编排脚本的高层业务流程。
main() {
  # 展示脚本内置自述，并按运行入口完成防误触确认。
  show_script_intro_and_wait
  # 执行入口下沉后的完整业务流程。
  run_main_business_flow "$@"
}

main "$@"

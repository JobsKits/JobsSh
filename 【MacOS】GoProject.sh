#!/bin/bash

# 收拢旧脚本原有执行顺序，后续复杂职责可继续拆分。
run_main_flow() {

# 检测是否已经安装了brew
if ! command -v brew &> /dev/null
then
    echo "brew 未安装，开始安装..."
    open https://brew.sh/
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ## brew环境变量设置
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/$(whoami)/.zprofile
    open /Users/$(whoami)/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "brew 已经安装，跳过安装步骤。"
    ## brew 升级
    brew update
    brew doctor
    brew -v
fi

# 🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛
## 如果没有执行权限，在这个sh文件的目录下，执行chmod u+x *.sh
## 加执行权限
function addExe(){
    
    filePath=$(dirname $0)/$(basename $0)
    echo "我在这里：$filePath" 

    # 定位📌于该文件的垂直文件夹
    folderPath=$(dirname $0)
    cd folderPath
    # 加权限
    fileFullName=$(basename $0)
    chmod u+x $fileFullName
}

## 通过 brew 安装 golong 语言环境，以及 IDE：vscode
function sysGoConf() {
<<'COMMENT'
    【参考资料】
    https://www.jianshu.com/p/7f9f73327fd8 Mac 安装 Golang 和 vscode
    https://blog.csdn.net/OMars/article/details/125356173 git 安装
COMMENT
    echo '1、安装 brew '
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo '2、通过 brew 安装 golang 环境 '
    brew install golang
    brew info go
    echo '3、通过 brew 安装 golang 开发IDE环境：visual-studio-code '
    brew cask install visual-studio-code
    open https://code.visualstudio.com/
    echo '4、 vscode 中 Go 的相关插件安装'
    cd $GOPATH/src/github.com/golang
    git clone https://github.com/golang/tools.git tools
}

## 添加默认值（字符串）
function defaultInput() {
    result=${1}
    if [${1} = $""]
    then
        # 什么都不输入，即默认值
        result=$'Test'
    fi  
}

## 配置项目依赖
function dependenceConf(){
    go get github.com/go-sql-driver/mysql ## mysql 的go语言驱动
    go get -u -v github.com/kardianos/govendor ## 安装 govendor
    # govendor -version ## 检查 govendor 是否安装成功
}

## 写文件内容
function writeFileContent(){
    # Todo
    echo ''
}

## 写入环境变量
## 在 ~/.bash_profile 文件内部搜索是否包含 GOPATH（全匹配：包括大小写和文字）
function GOPATHConf(){
<<'COMMENT'
grep返回的退出状态为0，表示成功。 
退出状态为1，表示没有找到。 
如果找不到指定的文件，退出状态为2
COMMENT

<<'COMMENT'
大于 -gt (greater than)
小于 -lt (less than)
大于或等于 -ge (greater than or equal)
小于或等于 -le (less than or equal)
不相等 -ne （not equal）
相等 -eq （equal）
COMMENT

    # 搜索不成功，说明还没有被写入，则写入【防止过度写入】
    # 配置文件更新以后不会自动刷新UI，需要重新open，才可以看到实时数据
    grep GOPATH ~/.bash_profile
    if [ $? -ne 0 ] ;then
        echo 'export PATH="$GOPATH/bin:$PATH"' >> ~/.bash_profile
        source ~/.bash_profile
    fi

    grep GOPATH ~/.zshrc
    if [ $? -ne 0 ] ;then
        echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.zshrc
        source ~/.zshrc
    fi
}

## 生成一些配置说明文件
function localGoEnvInfo(){
    ### 先清空
    echo "" > localGoEnvInfo.md
    ### 再写入
    echo "【❤️golang的环境配置】" >> localGoEnvInfo.md
    go env >> localGoEnvInfo.md
    echo "【❤️OS的环境变量】" >> localGoEnvInfo.md
    sed 's/:/\n/g' <<< "$PATH" >> localGoEnvInfo.md
    open localGoEnvInfo.md
}

## 项目初始化
function projInit(){
    # 📌定位到桌面
    cd Desktop/
    # 先定义项目文件夹
    printf '【自动化前置部署Go项目】\n\n'
    # 读取键盘输入，回车结束监听记录
    echo "【温馨提示：如果什么都没有输入，那么启用默认文件夹名Test】"
    read -p "请输入项目文件夹名字,以回车结束:" folder_name

    defaultInput $folder_name
    folder_name=${result}
    # echo "The value of var is ${result}"

    mkdir ${folder_name}
    echo -n "已经在桌面建立一个名为:${folder_name}的文件夹，并打开他"
    open ${folder_name} 
    # 📌定位到刚才创立的项目文件夹
    cd ${folder_name}
    # 用mod管理项目
<<'COMMENT'
go.mod文件一旦创建后，它的内容将会被go toolchain全面掌控。
go toolchain会在各类命令执行时，比如go get、go build、go mod等修改和维护go.mod文件。
COMMENT
    go mod init gone
    # 用Visual Studio Code作为IDE编辑代码[可以放在最后]
    code .
}

# 🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛🌛

projInit # 项目初始化

# 读取键盘输入，回车结束监听记录
echo "【温馨提示：如果什么都没有输入，那么启用默认文件名Test】"
read -p "请输入新建文件名字，以回车结束:" file_name

defaultInput $file_name
file_name=${result}
# echo "The value of var is ${result}"

# 新建一个文件，命名为Test
file_name=$file_name$".go"
Touch $file_name

echo ${file_name}

# writeFileContent ${file_name} # 写内容到文件

cat>${file_name}<<EOF

package main

import (
    "github.com/gin-gonic/gin"
)

func main() {
    r := gin.Default()
    r.GET("/ping", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "message": "pong",
        })
    })
    r.Run() // listen and serve on 0.0.0.0:8080 (for windows "localhost:8080")
}
EOF

go run $file_name # ①下载写入内容的依赖。依赖下载完成，会生成go.sum文件
dependenceConf # ②下载本脚本文件头部配置的依赖。依赖下载完成，会生成go.sum文件

localGoEnvInfo # 生成一些配置说明文件
GOPATHConf # GOPATH 配置
}

# 统一收口脚本入口，仅委托已经拆分完成的业务流程。
main() {
  # 主入口只负责委托完整业务流程，复杂逻辑统一下沉。
  run_main_flow "$@"
}

main "$@"

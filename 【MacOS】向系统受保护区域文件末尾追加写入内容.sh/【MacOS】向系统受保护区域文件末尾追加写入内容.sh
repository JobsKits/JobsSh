#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】向系统受保护区域文件末尾追加写入内容.sh
# - 核心用途：执行“向系统受保护区域文件末尾追加写入内容”对应的自动化任务。
# - 影响范围：可能修改当前项目、用户环境或脚本指定的目标。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。
# 打印脚本内置自述，并按运行入口决定是否等待用户确认。
show_script_intro_and_wait() {
  print -r -- '============================== 脚本内置自述 =============================='
  print -r -- '脚本名称：【MacOS】向系统受保护区域文件末尾追加写入内容.sh'
  print -r -- '核心用途：执行“向系统受保护区域文件末尾追加写入内容”对应的自动化任务。'
  print -r -- '影响范围：可能修改当前项目、用户环境或脚本指定的目标。'
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
# 执行当前流程中的独立业务步骤：处理当前语句。
<<'COMMENT'
    # 📌定位到桌面
    cd Desktop/
    echo "/Users/"${USER}"/Desktop"

    cp /private/etc/hosts /Users/jobs/Desktop/  
COMMENT

# 执行当前流程中的独立业务步骤：处理当前语句。
<<'COMMENT'
该脚本的工作目标

以 /etc/hosts 为例 
将 /etc/hosts 拷贝到系统桌面 
进行文件修改
复制回原路径，进行替换
COMMENT

# 相关变量的定义
read "?拖入需要修改的保护区文件:" filePath # 读取键盘输入，回车结束监听记录
## 文件全名（包含后缀名）
fileFullName=${filePath##*/}
## 文件的后缀名（只针对最右边的一个后缀名有效）
fileSuffixName=${filePath##*.}
## 文件的后缀名（多后缀名有效）
fileSuffixName2=${filePath#*.}
## 文件所在目录路径
folderPath=${filePath%/*}
## 文件所在文件夹名
folderName=${folderPath##*/}

## 判定路径不允许是桌面
if [ "$folderPath" = "/Users/"${USER}"/Desktop" ]; then
    # echo "Paths are equal."
    echo "桌面不允许执行此操作！"
else
    # echo "Paths are different."
    cp $filePath "/Users/"${USER}"/Desktop"
fi

## 接受键盘输入的内容，并追加写入文件末尾
read "?请输入需要追加写入的内容，以回车结束:" file_content
fileCopy_fullname="/Users/"${USER}"/Desktop/"$fileFullName
# 输出当前步骤的提示或执行进度。
echo $fileCopy_fullname
# 执行当前流程中的独立业务步骤：cat。
cat>>${fileCopy_fullname}<<EOF
$file_content
EOF

## 写成功了以后，拷贝回原路径
cp $fileCopy_fullname $filePath
}
# 初始化 zsh 通配符策略。
initialize_script_runtime() {
  setopt NO_NOMATCH TYPESET_SILENT
}
# 编排脚本的高层业务流程。
main() {
  show_script_intro_and_wait # 展示脚本内置自述，并按运行入口完成防误触确认。
  initialize_script_runtime # 确认后初始化 zsh 运行选项。
  run_main_business_flow "$@" # 执行入口下沉后的完整业务流程。
}

main "$@"

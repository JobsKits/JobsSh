#!/bin/zsh

# 收拢旧脚本原有执行顺序，后续复杂职责可继续拆分。
run_main_flow() {

# 提示用户输入路径
read "?📁 请输入要处理的文件夹路径: " TARGET_DIR

# 检查 SetFile 是否可用
if ! command -v SetFile &> /dev/null; then
  echo "⚠️ 未找到 SetFile 命令，请先安装：xcode-select --install"
  exit 1
fi

# 检查路径有效性
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "❌ 路径无效：$TARGET_DIR"
  exit 1
fi

# 递归查找所有普通文件
find "$TARGET_DIR" -type f | while read -r file; do
  SetFile -a E "$file"
  echo "✅ 隐藏扩展名：$file"
done

echo "🎉 完成：已隐藏 $TARGET_DIR 及其所有子目录下的文件扩展名"
}

# 统一收口脚本入口，仅委托已经拆分完成的业务流程。
main() {
  # 主入口只负责委托完整业务流程，复杂逻辑统一下沉。
  run_main_flow "$@"
}

main "$@"

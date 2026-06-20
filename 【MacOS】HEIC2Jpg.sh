#!/bin/bash

# 收拢旧脚本原有执行顺序，后续复杂职责可继续拆分。
run_main_flow() {
# 需要在桌面建立一个2的文件夹（里面是）*.heic
mkdir -p /Users/jobs/Desktop/3
find /Users/jobs/Desktop/2 -maxdepth 1 -iname "*.heic" | while read file; do
  filename=$(basename "$file")
  filename_no_ext="${filename%.*}"
  sips -s format jpeg "$file" --out /Users/jobs/Desktop/3/"$filename_no_ext".jpg
done
}

# 统一收口脚本入口，仅委托已经拆分完成的业务流程。
main() {
  # 主入口只负责委托完整业务流程，复杂逻辑统一下沉。
  run_main_flow "$@"
}

main "$@"

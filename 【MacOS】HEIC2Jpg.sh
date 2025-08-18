#!/bin/bash
# 需要在桌面建立一个2的文件夹（里面是）*.heic
mkdir -p /Users/jobs/Desktop/3
find /Users/jobs/Desktop/2 -maxdepth 1 -iname "*.heic" | while read file; do
  filename=$(basename "$file")
  filename_no_ext="${filename%.*}"
  sips -s format jpeg "$file" --out /Users/jobs/Desktop/3/"$filename_no_ext".jpg
done

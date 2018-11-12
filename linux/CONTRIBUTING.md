# 如何生成新的 Patch

- 下载新的内核源码
- （可选）新建一个空的 Git，把当前状态提交成一个 commit
- 应用老内核的 Patch
- 复制老内核的 .config 文件
- 运行 `make oldconfig`
- 测试各功能无误后，运行 `make savedefconfig` 
- 运行 `mv defconfig arch/arm/configs/saltedfishpi_defconfig`
- 使用 `git diff` 生成新内核的 Patch
- 加入到仓库中并更新 `README.md`
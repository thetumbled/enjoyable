# 补丁说明

基于 [shirosaki/enjoyable](https://github.com/shirosaki/enjoyable) v1.2.1。

排错与踩坑清单见 **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**。

## 代码变更

### `Classes/NJDevice.m`

1. 设备 UID：`VID:PID:index` → **`{产品名}:{VID}:{PID}`**（十六进制 VID/PID）  
2. 同名同型号第二只手柄：`:index` 后缀，如 `BEITONG...:045e:028e:2`  
3. 忽略 `AppleGCSyntheticDevice`（`GamePad-*`、无 Transport）

### `Classes/NJInputController.m`

- `initWithDevice:` 返回 `nil` 时不加入设备列表

### `Classes/NJPermissions.m`

- 启用映射前检查 **辅助功能**（不反复调用系统 TCC 弹窗）  
- 启动时不自动弹权限框  

### `Classes/EnjoyableApplicationDelegate.m`

- 工具栏启动/停止按钮：绘制为图片、清除 toolbar 旧缓存  
- 权限与按钮状态联动  

### `Classes/NJDeviceViewController.m`

- 手柄列表改为紧凑普通行（非 group item）

### `Categories/NSRunningApplication+NJPossibleNames.m`

- `frontWindowTitle` 为空时返回 `nil`（修复 macOS 26 切换应用崩溃）

### 工程 / 构建

- `VALID_ARCHS = arm64 x86_64`，`MACOSX_DEPLOYMENT_TARGET = 10.13`  
- `build_and_install.sh`：安装前退出旧进程、ad-hoc 签名  

## 映射升级

补丁后 **旧映射档键名变化**，需在 Enjoyable 里重新配置。

## 文档

| 文件 | 内容 |
|------|------|
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | 权限、Steam、UI、双手柄等踩坑 |
| [LICENSE](LICENSE) | MIT 许可与上游版权 |

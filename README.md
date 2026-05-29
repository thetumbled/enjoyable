# Enjoyable（Mac 手柄映射）

将游戏手柄映射为键盘/鼠标，供仅支持键鼠的 Mac 游戏使用。

本仓库为 **维护中的补丁 fork**，基于 [shirosaki/enjoyable](https://github.com/shirosaki/enjoyable) v1.2.1（上游作者 Joe Wreschnig 等，见 [LICENSE](LICENSE)）。

## 本 fork 主要改动

- 双手柄 UID：`产品名:VID:PID`，避免同款 Xbox 360 ID 冲突  
- 过滤 macOS 虚拟 `GamePad-*` 节点  
- 辅助功能权限提示与启动/停止按钮 UI  
- 适配较新 macOS（含 Apple Silicon 编译、崩溃修复）  

详见 [PATCH-NOTES.md](PATCH-NOTES.md)。**踩坑与排错**见 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)。

## 编译安装

需要完整 **Xcode**（非仅 Command Line Tools）。

```bash
chmod +x build_and_install.sh
./build_and_install.sh
```

安装目标：`/Applications/Enjoyable.app`。

安装后请在 **系统设置 → 隐私与安全性 → 辅助功能** 中授权；若重装后权限失效，见 [TROUBLESHOOTING.md](TROUBLESHOOTING.md#2-重装后权限明明开了仍提示无权限)。

## 使用要点

1. 连接手柄，在 Enjoyable 中配置映射  
2. 点 **▶ 启动**  
3. **切换到游戏窗口** 再操作手柄  
4. 与 Steam Input 不要同时用于同一游戏；玩 Overcooked 2 建议完全退出 Steam  

## 需求

- macOS 10.13+（本 fork 在 Apple Silicon / macOS 26 上验证）  
- USB 或蓝牙 HID 手柄  

## 许可

MIT License。完整条文与上游版权说明见 [LICENSE](LICENSE)。

应用内 **关于** 窗口不再展示原作者署名行；法律要求的版权声明保留在 `LICENSE` 及源码文件头中。

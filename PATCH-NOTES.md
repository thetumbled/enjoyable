# Enjoyable 补丁说明（产品名 + VID + PID）

基于 [shirosaki/enjoyable](https://github.com/shirosaki/enjoyable) v1.2.1。

## 变更

### `Classes/NJDevice.m`

1. **设备 UID** 由 `VID:PID:index` 改为 **`{产品名}:{VID}:{PID}`**（十六进制 VID/PID）。
   - 示例：`Controller:045e:028e` 与 `BEITONG_A1N2_XINPUT_GAMEPAD:045e:028e` 不再冲突。
   - 换 USB 口仍有效（未使用 LocationID）。
2. **同名同型号第二只手柄** 仍用 `:index` 后缀，例如 `BEITONG...:045e:028e:2`。
3. **忽略** macOS `AppleGCSyntheticDevice`（`GamePad-1`、无 Transport），列表只保留物理 USB 手柄。

### `Classes/NJInputController.m`

- `initWithDevice:` 返回 `nil` 时不再加入设备列表。

### `Classes/NJPermissions.m`（新增）

- 启动时与点击 ▶ 启用模拟时，检查 **辅助功能** 与 **输入监控** 权限。
- 缺失时弹出系统提示并引导打开「系统设置 → 隐私与安全性」。
- 原版 Enjoyable **不会** 自动请求这些权限，无权限时 `CGEventPost` 会静默失败，映射看起来「已启用但不生效」。

## 使用注意

1. **必须授予两项权限**：辅助功能（模拟键盘）、输入监控（读取手柄）。
2. 授权后 **完全退出并重启 Enjoyable**（⌘Q，不要只关窗口）。
3. 点击 ▶ 后，**切换到游戏窗口** 再按手柄——Enjoyable 在前台时只用于配置映射，不会向其他应用发送按键。
4. 玩 Overcooked 2 时 **完全退出 Steam**，避免与 Enjoyable 抢输入。

## 编译安装

```bash
chmod +x build_and_install.sh
./build_and_install.sh
```

需要已安装 **Xcode**（非仅 Command Line Tools）。

## 注意

- 升级后 **旧映射档键名变化**，需在 Enjoyable 里重新映射手柄按键。
- 两只 **完全相同型号** 的手柄仍会共用前缀，第二只占 `:2` 后缀。

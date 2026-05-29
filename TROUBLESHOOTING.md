# Enjoyable 补丁版 — 踩坑备忘

本文档记录 Mac（尤其 Apple Silicon + 较新 macOS）上使用本 fork 时遇到过的问题与对策，避免重复踩坑。

上游基础：[shirosaki/enjoyable](https://github.com/shirosaki/enjoyable) v1.2.1（MIT）。

---

## 1. 映射「已启用」但不生效

| 现象 | 常见原因 |
|------|----------|
| 点了启动，游戏无反应 | 未授予 **辅助功能**，或授权的是旧签名 |
| 只有配置时手柄有反应 | **未切到游戏窗口**——Enjoyable 在前台时只预览映射，不发送按键 |
| 偶尔完全无输入 | **Steam 未退出**，与 Enjoyable 抢 HID/输入 |

**正确流程：**

1. 系统设置 → 隐私与安全性 → **辅助功能** → 开启 Enjoyable  
2. Enjoyable 里配置映射 → 点 **▶ 启动**  
3. **⌘Tab 切到游戏**（或文本编辑先自测）  
4. 玩 Overcooked 2 时 **完全退出 Steam**

模拟键盘只需 **辅助功能**。「输入监控」对手柄 HID 读取通常不是硬性门槛；若列表里完全没有手柄，可再尝试添加输入监控。

---

## 2. 重装后权限「明明开了」仍提示无权限

`build_and_install.sh` 每次安装都会对 app 做 **ad-hoc 重签名**。macOS 的 TCC 权限绑定 **代码签名**，不是只看名字。

**症状：** 辅助功能列表里 Enjoyable 仍是开启，但应用认为未授权。

**处理：**

1. 辅助功能列表中选中 Enjoyable → **− 删除**  
2. **+** 重新添加 `/Applications/Enjoyable.app`  
3. **⌘Q** 完全退出 Enjoyable 后重开  

每次 `./build_and_install.sh` 重装后若权限失效，重复上述步骤。使用固定开发者证书签名可减少此问题。

**不要用** `tccutil reset` 清权限，除非你知道在做什么。

---

## 3. Xcode Run 与 /Applications 不是同一个应用

| 启动方式 | 路径 | 权限 |
|----------|------|------|
| Xcode ▶ Run | `DerivedData/.../Enjoyable.app` | 需单独在系统设置里授权 |
| 安装版 | `/Applications/Enjoyable.app` | 单独授权 |

二者 **权限不共用**。日常玩游戏请用安装版；调试完用 `build_and_install.sh` 装回 `/Applications`。

---

## 4. 两只手柄映射互相覆盖

**原因：** 不同手柄伪装成相同 Xbox 360 ID（`045e:028e`），原版 UID 为 `VID:PID:index`，映射键名冲突。

**本 fork：** UID 改为 `{产品名}:{VID}:{PID}`，并忽略 macOS 虚拟 `GamePad-*` 节点。

**注意：**

- 升级补丁后 **旧映射档键名变化**，需重新配置  
- 两只 **完全同款** 手柄仍可能共用前缀，第二只为 `:2` 后缀  
- 检测脚本见 MyGame 仓库：`Overcooked2/detect_controllers.py`

---

## 5. 工具栏「启动」按钮显示异常

**原版设计：** 工具栏按钮是 **纯图标** 代理，点击触发隐藏菜单项 `Enable`，不是普通文字按钮。

| 踩坑 | 说明 |
|------|------|
| 改成 `title` 不显示 | 按钮 cell 为 image-only 模式 |
| 纯白块 | 去掉图标后未绘 replacement 图 |
| `/Applications` 无字、Xcode 有字 | **工具栏自动保存** 恢复了旧 36×25 布局 |

**本 fork 做法：** 将「▶ 启动 / ■ 停止」绘制成 `NSImage`；关闭工具栏 autosave；首次启动清除旧 toolbar 配置（见 `simulationToolbarLayoutVersion`）。

若仍异常，可手动清缓存：

```bash
defaults delete com.yukkurigames.Enjoyable \
  "NSToolbar Configuration AC1F5C48-4C16-4C9D-9779-B783AF35E2E1" 2>/dev/null
open /Applications/Enjoyable.app
```

---

## 6. 左侧手柄列表间距过大

**原因：** 顶层设备被标为 `isGroupItem`，系统按分组行加大行距。

**本 fork：** 改为普通列表行，`rowHeight=20`，`intercellSpacing` 高度为 0。

---

## 7. 编译与安装

| 问题 | 对策 |
|------|------|
| 「已损坏，无法打开」 | 工程曾只允许 x86_64，M 芯片编出空包；现应为 `arm64` + `VALID_ARCHS` |
| 需要完整 Xcode | 不能只有 Command Line Tools |
| 首次 Gatekeeper | 右键 → 打开，或脚本内 `codesign` + `xattr -cr` |

```bash
chmod +x build_and_install.sh
./build_and_install.sh
```

---

## 8. macOS 26 相关崩溃

切换前台应用时若因 `frontWindowTitle` 为空崩溃，本 fork 已在 `NSRunningApplication+NJPossibleNames.m` 中修复（空窗口标题时返回 `nil`）。

---

## 9. Overcooked 2 专用备忘

- Mac 版原生手柄支持差，需 **手柄 → 键盘**（Enjoyable）  
- **不能** 像 Dead Cells 那样替换 `libSDL2`（Unity 版无此库）  
- 游戏内选 **键盘双人**；键位与 Enjoyable 映射的 Mac 物理键一致（Option=⌥，Control=⌃）  
- Dead Cells 修复见 MyGame 仓库 `DeadCells/`

---

## 10. 相关文件速查

| 文件 | 用途 |
|------|------|
| `PATCH-NOTES.md` | 代码改动摘要 |
| `build_and_install.sh` | 编译并安装到 `/Applications` |
| `~/Library/Preferences/com.yukkurigames.Enjoyable.plist` | 映射配置 |
| `LICENSE` | 上游 MIT 许可全文 |

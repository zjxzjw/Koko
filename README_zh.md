# koko

[English](README.md) | [中文](README_zh.md)

> 一款极简菜单栏/系统托盘工具，用于监控 LLM 提供商余额 — 支持 DeepSeek、OpenAI 及任何兼容 OpenAI 的 API。

---

## 界面预览

| 仪表盘 | 托盘弹窗 |
|---|---|
| ![仪表盘](readme-1.png) | ![托盘弹窗](readme-2.png) |

## 功能特性

- **系统托盘集成** — 常驻 macOS 菜单栏或 Windows 系统托盘，点击即可查看余额，窗口失焦自动隐藏。
- **双重视图** — 紧凑弹窗（仅余额）与完整仪表盘（含图表和模型用量明细）。
- **多提供商支持** — 在 DeepSeek、OpenAI 之间切换，或添加自定义 OpenAI 兼容接口。
- **余额监控** — 实时展示剩余余额、累计使用量和总充值金额，自动识别货币类型（USD/CNY/EUR/GBP）。
- **每日费用图表** — 当月每日支出的柱状图。
- **模型用量明细** — 按模型展示用量 API 返回的费用明细。
- **本地持久化** — 通过 `shared_preferences` 在本地存储 API Key 和提供商配置。

## 支持平台

| 平台 |
|----------|
| macOS    |
| Windows  |

## 技术栈

| 依赖 | 用途 |
|---|---|
| `window_manager` | 无边框、置顶窗口管理 |
| `tray_manager` | 系统托盘 / 菜单栏图标与菜单 |
| `dio` | 提供商 API 的 HTTP 客户端 |
| `fl_chart` | 每日费用柱状图 |
| `shared_preferences` | 本地键值存储 |

## 项目结构

```
lib/
├── main.dart                  # 应用入口，窗口/托盘管理，视图切换
├── models/
│   └── provider_model.dart     # ProviderConfig、BalanceResult、ModelUsage、DailyUsage
├── services/
│   ├── api_service.dart        # DeepSeek & OpenAI 余额/用量 API 调用
│   └── storage_service.dart    # SharedPreferences 持久化层
└── ui/
    ├── dashboard_view.dart     # 完整仪表盘，含图表和模型用量明细
    ├── settings_view.dart      # 添加/编辑/删除提供商配置
    └── tray_popup_view.dart    # 紧凑余额弹窗
```

## 快速开始

### 环境要求

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.10.7
- 已启用 macOS / Windows 桌面端开发（`flutter config --enable-macos-desktop` / `flutter config --enable-windows-desktop`）

### 开发

```bash
git clone <repo-url> && cd koko
flutter pub get
flutter run -d macos    # 或 windows
```

### 构建

```bash
# macOS
flutter build macos

# Windows
flutter build windows
```

## 配置

首次启动时会自动生成两个默认提供商：

- **DeepSeek** — `https://api.deepseek.com`
- **OpenAI** — `https://api.openai.com`

### 添加提供商

1. 打开仪表盘，点击**偏好设置**。
2. 点击 **+** 按钮添加新提供商。
3. 填写以下信息：
   - **名称** — 例如 `My Proxy`
   - **基础 URL** — 任意 OpenAI 兼容接口（如 `https://api.openai.com`、`https://api.deepseek.com` 或自定义代理）
   - **API Key** — `sk-...`
4. 保存后，通过仪表盘上的下拉菜单切换到新提供商。

### 支持的 API 格式

| 提供商 | 余额接口 | 用量接口 |
|---|---|---|
| DeepSeek | `GET /user/balance` | `GET /v1/usage/metrics` |
| OpenAI | `GET /v1/organization/costs` | `GET /v1/usage` |
| 自定义 | 自动识别 DeepSeek 或 OpenAI 风格 | 回退到成功响应的接口 |

OpenAI 账单查询需要使用**管理员 API Key**，可在 [platform.openai.com → Settings → Admin Keys](https://platform.openai.com) 创建。

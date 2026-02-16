# 票务打印助手 (Ticket Printing App) 🖨️

一个基于 **Flutter Clean Architecture** 构建的现代化票务打印与发票管理应用。支持 Android 端本地数据库存储、PDF 发票生成与分享、以及蓝牙/WiFi 打印机对接。

## ✨ 核心功能 (Features)

*   **选品开票 (Invoice Creation)**:
    *   可视化的商品选择界面，支持网格布局与搜索。
    *   **动态购物车**: 点击卡片添加，支持数量加减，自动计算总价。
    *   **结算中心**: 支持金额抹零 (Rounding) 与整单减免 (Discount Amount)。
    *   **防误触 UI**: 大字号适配，胶囊形数量控制器，防止误操作。

*   **商品库管理 (Product Management)**:
    *   支持添加、编辑、删除商品。
    *   **图片支持**: 可为商品添加本地图片，提升识别度。
    *   支持自定义单位（个、箱、千克等）。

*   **开票历史 (History)**:
    *   本地保存所有开票记录 (SQLite)。
    *   **智能筛选**: 支持按今日、本周、本月或自定义日期范围筛选。
    *   **重打/分享**: 支持查看历史发票详情，并重新生成 PDF 进行打印或分享。

*   **设置 (Settings)**:
    *   商户信息配置（名称、电话、地址）。
    *   **默认保存路径**: 支持自定义 PDF 保存文件夹，并未 Android 10+ 适配了权限处理。

## 🏗️ 技术架构 (Architecture)

本项目采用 **Clean Architecture** 分层架构，确保代码的高内聚、低耦合与可测试性：

*   **Presentation Layer (UI)**: Flutter Widgets, Pages, ViewModels (`Provider`).
*   **Domain Layer (Business Logic)**: Entities, Repository Interfaces, Use Cases.
*   **Data Layer (Infrastructure)**:
    *   **Database**: `drift` (SQLite) 用于高频读写。
    *   **Storage**: `mmkv` 用于键值对存储 (Settings)。
    *   **Services**: `printing` (PDF/Print), `file_picker`, `permission_handler`.

## 📦 安装与构建 (Installation & Build)

### 环境要求
*   Flutter SDK: >=3.0.0
*   Dart SDK: >=3.0.0
*   Android Studio / VS Code
*   Java JDK: 11+ (推荐 JDK 17)

### 初始化
```bash
# 1. 获取依赖
flutter pub get

# 2. 生成代码 (Database & JSON)
dart run build_runner build --delete-conflicting-outputs
```

### 运行与打包
```bash
# 运行 (Debug)
flutter run

# 打包 APK (Release)
flutter build apk --release
```
生成的 APK 文件位于: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📜 许可证 (License)

本项目遵循 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

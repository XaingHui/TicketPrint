# 票务 App (Ticket Printing)

## 版本 v1.0 - 基础架构版

### ⚠️ 环境配置问题解决

如果您在终端运行命令时遇到 `'flutter' 不是内部或外部命令，也不是可运行的程序` 或 `无法将“flutter”项识别为 cmdlet`，说明系统环境变量中没有配置 Flutter SDK 的路径。

**解决方法：**

1.  **找到 Flutter SDK 路径**：
    确认您下载并解压 Flutter SDK 的位置（例如：`D:\flutter`）。
2.  **添加到环境变量 (Path)**：
    - 在 Windows 搜索栏输入 "环境" 并选择 "编辑系统环境变量"。
    - 点击 "环境变量" 按钮。
    - 在 "用户变量" 列表中找到 `Path`，双击编辑。
    - 点击 "新建"，输入 `D:\flutter\bin` (请替换为您实际的 SDK 路径)。
    - 点击所有 "确定" 保存。
3.  **重启终端**：
    关闭当前的 VS Code 或终端窗口，重新打开以生效。
4.  **验证**：
    运行 `flutter doctor`，如果能看到输出，说明配置成功。

---

### 📦 第一次运行指南

环境配置好后，请依次执行以下命令来初始化项目：

#### 1. 安装依赖包
下载项目所需的第三方库（如 drift, provider, printing 等）。
```powershell
flutter pub get
```

#### 2. 生成代码文件
本项目使用了 `drift` (数据库) 和 `json_serializable` 等代码生成工具，**必须**执行此步才能运行，否则会报错找不到 `.g.dart` 文件。
```powershell
dart run build_runner build --delete-conflicting-outputs
```

#### 3. 运行 App
连接手机或启动模拟器后运行：
```powershell
flutter run
```

---

### 📂 项目结构说明

- **lib/main.dart**: 程序入口。
- **lib/service_locator.dart**: 依赖注入配置（单例服务注册）。
- **lib/domain/**: 业务实体（如 `Invoice` 发票, `Product` 商品）。
- **lib/data/**: 数据层实现（数据库、本地存储、PDF生成）。
- **lib/application/**: 视图模型 (`InvoiceViewModel`)，处理业务逻辑。

### ✨ 当前功能
- 基础 Clean Architecture 架构搭建完成。
- 集成 SQLite 数据库 (Drift)。
- 集成 MMKV 本地存储。
- 集成 PDF 生成与打印服务。
- 完成了商品 (`Product`) 和发票 (`Invoice`) 的数据模型设计。

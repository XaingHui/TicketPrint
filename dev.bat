@echo off
chcp 65001 >nul
echo 正在以 Windows 桌面模式启动预览...

echo 提示：在控制台输入 'r' 键可手动触发热重载 (Hot Reload)
echo ======================================================

:: -d windows 表示指定 Windows 设备
:: --enable-software-rendering (可选) 如果你显卡驱动有问题可以加上
call flutter run -d windows

pause
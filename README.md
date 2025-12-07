# 手动双面助手

一个用于处理PDF文件的Web应用程序，可以自动分离PDF的奇偶数页并逆序排列，方便双面打印。

## 功能特性

- 上传PDF文件
- 自动分离奇数页和偶数页
- 页码逆序排列（便于手动双面打印）
- 简洁的用户界面
- 上传进度显示
- 处理进度显示
- 页码信息预览
- 跨浏览器兼容性

## 系统要求

- Python 3.6+
- pip

## 安装和运行

### 自动安装（推荐）

#### Linux系统：
如果遇到权限问题，可以先运行：
chmod +x setup_linux.sh
```bash
./setup_linux.sh
```

#### Windows系统：
```cmd
setup_windows.bat
```

### 手动安装：

1. 安装依赖：
```bash
pip install flask PyPDF2
```

2. 运行应用：
```bash
python print_helper.py
```

## 使用方法

1. 运行脚本后，应用程序将在 `http://127.0.0.1:5000` 启动
2. 在浏览器中打开上述地址
3. 上传PDF文件
4. 点击"开始处理"按钮
5. 等待处理完成
6. 下载分离后的奇数页和偶数页PDF文件

## 工作流程

1. 上传PDF文件
2. 系统读取PDF并分离页面
3. 奇数页（1, 3, 5...）按逆序排列（...5, 3, 1）
4. 偶数页（2, 4, 6...）按逆序排列（...6, 4, 2）
5. 生成两个独立的PDF文件供下载

## 文件说明

- `print_helper.py` - 主应用程序文件
- `setup_linux.sh` - Linux自动配置脚本
- `setup_windows.bat` - Windows自动配置脚本

## 技术栈

- 后端：Flask (Python)
- 前端：HTML/CSS/JavaScript
- PDF处理：PyPDF2

## 浏览器兼容性

支持所有现代浏览器（Chrome, Firefox, Safari, Edge等）
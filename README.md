# 手动双面助手

一个多格式文件处理工具，可将各种文件格式转换为PDF并自动分离奇偶数页，方便双面打印。

## 功能特性

- 支持多种文件格式：PDF、图片、文档等
- 自动转换为PDF格式
- 自动分离奇数页和偶数页
- 页码逆序排列（便于手动双面打印）
- 简洁的用户界面
- 上传进度显示
- 处理进度显示
- 页码信息预览
- 跨浏览器兼容性

## 支持的文件格式

### 文档类型
- PDF (.pdf)
- Word文档 (.doc, .docx)
- 纯文本 (.txt)
- 富文本 (.rtf)
- HTML/HTM (.html, .htm)
- Markdown (.md)
- OpenDocument (.odt, .ods, .odp)

### 图片类型
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- BMP (.bmp)
- TIFF (.tiff)
- WEBP (.webp)

## 系统要求

- Python 3.7+
- pip

## 安装和运行

### 一键安装（推荐）

#### 一行指令安装运行（自动安装Git并克隆运行）：
```bash
command -v git >/dev/null 2>&1 || { apt-get update && apt-get install -y git; } && git clone https://github.com/wzmwayne/print_helper.git && cd print_helper && pip install -r requirements.txt && python3 print_helper.py
```

#### 通用系统版本：
```bash
{ command -v git >/dev/null 2>&1 || (command -v apt-get >/dev/null 2>&1 && sudo apt-get update && sudo apt-get install -y git || command -v yum >/dev/null 2>&1 && sudo yum install -y git || command -v brew >/dev/null 2>&1 && brew install git) } && git clone https://github.com/wzmwayne/print_helper.git && cd print_helper && pip3 install -r requirements.txt && python3 print_helper.py
```

#### 自动安装脚本：
```bash
curl -fsSL https://raw.githubusercontent.com/wzmwayne/print_helper/master/install.sh | bash
```

### 手动安装

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

#### 手动安装步骤：

1. 安装依赖：
```bash
pip install -r requirements.txt
```

2. 运行应用：
```bash
python print_helper.py
```

## 使用方法

1. 运行脚本后，应用程序将在 `http://127.0.0.1:5000` 启动
2. 在浏览器中打开上述地址
3. 上传支持的文件（PDF/图片/文档等）
4. 点击"开始处理"按钮
5. 等待文件转换和处理完成
6. 下载分离后的奇数页和偶数页PDF文件

## 工作流程

1. 上传文件（支持多种格式）
2. 系统自动将文件转换为PDF格式
3. 读取PDF并分离页面
4. 奇数页（1, 3, 5...）按逆序排列（...5, 3, 1）
5. 偶数页（2, 4, 6...）按逆序排列（...6, 4, 2）
6. 生成两个独立的PDF文件供下载

## 文件说明

- `print_helper.py` - 主应用程序文件
- `requirements.txt` - Python依赖包列表
- `setup_linux.sh` - Linux自动配置脚本
- `setup_windows.bat` - Windows自动配置脚本
- `install.sh` - 一键安装脚本
- `README.md` - 项目说明文档

## 技术栈

- 后端：Flask (Python)
- 前端：HTML/CSS/JavaScript
- 文件处理：
  - PDF处理：PyPDF2, PyMuPDF
  - 图片处理：Pillow (PIL)
  - 文档处理：python-docx
  - PDF生成：ReportLab

## 浏览器兼容性

支持所有现代浏览器（Chrome, Firefox, Safari, Edge等）
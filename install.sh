#!/bin/bash

# 一键安装脚本 - 手动双面打印助手
# 支持Linux/macOS/Windows(WSL)
# 仓库地址: https://github.com/wzmwayne/print_helper

echo "🚀 开始安装手动双面打印助手..."
echo "仓库地址: https://github.com/wzmwayne/print_helper"
echo ""

# 检查系统环境
OS_TYPE=$(uname -s)
echo "检测到系统: $OS_TYPE"

# 检查Python是否已安装
echo "检查Python环境..."
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    echo "✅ Python3 已安装"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
    echo "✅ Python 已安装"
else
    echo "❌ 未检测到Python，请先安装Python 3.7或更高版本"
    echo "下载地址: https://www.python.org/downloads/"
    exit 1
fi

# 检查pip是否已安装
echo "检查pip..."
if $PYTHON_CMD -m pip --version &> /dev/null; then
    echo "✅ pip 已安装"
else
    echo "❌ 未检测到pip，正在安装..."
    $PYTHON_CMD -m ensurepip --upgrade
fi

# 创建安装目录
INSTALL_DIR="$HOME/print_helper"
echo "创建安装目录: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 下载仓库文件
echo "正在下载最新版本..."
if command -v git &> /dev/null; then
    echo "使用Git克隆仓库..."
    git clone https://github.com/wzmwayne/print_helper.git .
else
    echo "Git未安装，使用curl下载..."
    # 下载主要文件
    curl -L -o print_helper.py https://raw.githubusercontent.com/wzmwayne/print_helper/master/print_helper.py
    curl -L -o requirements.txt https://raw.githubusercontent.com/wzmwayne/print_helper/master/requirements.txt
    curl -L -o setup_linux.sh https://raw.githubusercontent.com/wzmwayne/print_helper/master/setup_linux.sh
    curl -L -o setup_windows.bat https://raw.githubusercontent.com/wzmwayne/print_helper/master/setup_windows.bat
    curl -L -o README.md https://raw.githubusercontent.com/wzmwayne/print_helper/master/README.md
fi

# 设置脚本权限
if [ "$OS_TYPE" = "Linux" ] || [ "$OS_TYPE" = "Darwin" ]; then
    chmod +x setup_linux.sh
    chmod +x install.sh
fi

# 安装Python依赖
echo "安装Python依赖包..."
$PYTHON_CMD -m pip install -r requirements.txt

# 创建启动脚本
echo "创建启动脚本..."
cat > start.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
python3 print_helper.py
EOF

if [ "$OS_TYPE" = "Linux" ] || [ "$OS_TYPE" = "Darwin" ]; then
    chmod +x start.sh
fi

# 创建桌面快捷方式 (Linux)
if [ "$OS_TYPE" = "Linux" ] && [ -d "$HOME/Desktop" ]; then
    echo "创建桌面快捷方式..."
    cat > "$HOME/Desktop/Print Helper.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=手动双面助手
Comment=手动双面打印助手 - 支持多种文件格式
Exec=$INSTALL_DIR/start.sh
Icon=application-pdf
Terminal=false
Categories=Office;
EOF
    chmod +x "$HOME/Desktop/Print Helper.desktop"
fi

# 安装完成
echo ""
echo "🎉 安装完成！"
echo ""
echo "使用方法："
echo "1. 进入安装目录: cd $INSTALL_DIR"
echo "2. 运行启动脚本: ./start.sh"
echo "   或者直接运行: $PYTHON_CMD print_helper.py"
echo ""
echo "程序启动后会自动打开浏览器，访问: http://127.0.0.1:5000"
echo ""
echo "如需卸载，请删除安装目录: rm -rf $INSTALL_DIR"
echo ""
echo "仓库地址: https://github.com/wzmwayne/print_helper"
echo "如有问题，请提交Issue或查看文档"
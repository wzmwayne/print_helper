@echo off
REM 自动配置脚本 - Windows系统
REM 作者：iFlow CLI
REM 功能：安装Python、安装pip、安装模块、运行print_helper.py

echo 开始自动配置...

REM 检查Python是否已安装
echo 检查Python是否已安装...
python --version >nul 2>&1
if errorlevel 1 (
    echo 未检测到Python，正在尝试安装...
    REM 如果在Windows上没有安装Python，可以使用winget或从官网下载
    echo 请手动安装Python，或使用winget install Python
    pause
    exit /b 1
) else (
    echo Python已安装
)

REM 检查pip是否已安装
echo 检查pip是否已安装...
python -m pip --version >nul 2>&1
if errorlevel 1 (
    echo 未检测到pip，正在安装...
    python -m ensurepip --upgrade
) else (
    echo pip已安装
)

REM 创建print_helper.py文件
echo 创建print_helper.py文件...
(
echo from flask import Flask, request, send_file, render_template_string, jsonify
echo from PyPDF2 import PdfReader, PdfWriter
echo import os
echo import tempfile
echo import threading
echo import time
echo import webbrowser
echo from threading import Timer

echo app = Flask(__name__)

echo # 全局变量用于存储处理进度
echo processing_progress = {"current": 0, "total": 0, "status": "ready"}

echo def allowed_file(filename):
echo     """检查文件类型"""
echo     return '.' in filename and filename.lower().endswith('.pdf')

echo def process_pdf_async(file_path, task_id):
echo     """异步处理PDF文件"""
echo     try:
echo         processing_progress["phase"] = "processing"
echo         processing_progress["status"] = "processing"
echo         processing_progress["current"] = 0
        
echo         # 读取PDF文件
echo         reader = PdfReader(file_path)
echo         total_pages = len(reader.pages)
echo         processing_progress["total"] = total_pages
        
echo         if total_pages == 0:
echo             processing_progress["status"] = "error"
echo             processing_progress["message"] = "PDF文件没有页面内容"
echo             processing_progress["phase"] = "error"
echo             return
        
echo         # 创建临时目录存储结果
echo         temp_dir = tempfile.mkdtemp()
echo         odd_path = os.path.join(temp_dir, '奇数页.pdf')
echo         even_path = os.path.join(temp_dir, '偶数页.pdf')
        
echo         # 处理奇数页（逆序）
echo         odd_writer = PdfWriter()
echo         odd_pages = []
        
echo         # 收集奇数页（索引从0开始，索引0=第1页是奇数页）
echo         for i in range(total_pages-1, -1, -1):
echo             if i %% 2 == 0:  # 索引为偶数的页面是奇数页
echo                 odd_pages.append(i)
echo             processing_progress["current"] = total_pages - i
echo             time.sleep(0.01)  # 稍微延迟以便显示进度
        
echo         # 添加奇数页到输出
echo         for page_num in odd_pages:
echo             odd_writer.add_page(reader.pages[page_num])
        
echo         # 保存奇数页PDF
echo         with open(odd_path, 'wb') as odd_file:
echo             odd_writer.write(odd_file)
        
echo         processing_progress["current"] = total_pages // 2
        
echo         # 处理偶数页（逆序）
echo         even_writer = PdfWriter()
echo         even_pages = []
        
echo         # 收集偶数页（索引从0开始，索引1=第2页是偶数页）
echo         for i in range(total_pages-1, -1, -1):
echo             if i %% 2 == 1:  # 索引为奇数的页面是偶数页
echo                 even_pages.append(i)
        
echo         # 添加偶数页到输出
echo         for page_num in even_pages:
echo             even_writer.add_page(reader.pages[page_num])
        
echo         # 保存偶数页PDF
echo         with open(even_path, 'wb') as even_file:
echo             even_writer.write(even_file)
        
echo         processing_progress["current"] = total_pages
echo         processing_progress["status"] = "completed"
echo         processing_progress["phase"] = "completed"
echo         processing_progress["result"] = {
echo             "odd_path": odd_path,
echo             "even_path": even_path,
echo             "total_pages": total_pages,
echo             "odd_pages": len(odd_pages),
echo             "even_pages": len(even_pages),
echo             "file_path": file_path  # 保存原始文件路径用于预览
echo         }
        
echo     except Exception as e:
echo         processing_progress["status"] = "error"
echo         processing_progress["message"] = str(e)

echo # HTML模板（极简设计，添加页码和预览功能）
echo HTML_TEMPLATE = '''^<!DOCTYPE html^>
echo ^<html lang="zh-CN"^>
echo ^<head^>
echo     ^<meta charset="UTF-8"^>
echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo     ^<title^>手动双面助手^</title^>
echo     ^<style^>
echo         * { 
echo             margin: 0; 
echo             padding: 0; 
echo             box-sizing: border-box; 
echo         }
echo         body { 
echo             font-family: Arial, sans-serif; 
echo             background-color: #f5f5f5;
echo             min-height: 100vh; 
echo             display: flex; 
echo             align-items: center; 
echo             justify-content: center; 
echo             padding: 20px; 
echo         }
echo         .container { 
echo             background: white; 
echo             border-radius: 8px; 
echo             box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
echo             padding: 30px; 
echo             width: 100%%; 
echo             max-width: 500px; 
echo             text-align: center; 
echo         }
echo         h1 { 
echo             color: #333; 
echo             margin-bottom: 5px; 
echo             font-size: 22px; 
echo         }
echo         .subtitle { 
echo             color: #666; 
echo             margin-bottom: 25px; 
echo             font-size: 13px; 
echo         }
echo         .upload-area { 
echo             border: 2px dashed #ccc; 
echo             border-radius: 6px; 
echo             padding: 30px 20px; 
echo             margin: 20px 0; 
echo             cursor: pointer; 
echo         }
echo         .upload-icon { 
echo             font-size: 40px; 
echo             margin-bottom: 10px; 
echo             color: #666;
echo         }
echo         .browse-btn { 
echo             background: #007bff; 
echo             color: white; 
echo             border: none; 
echo             padding: 10px 20px; 
echo             border-radius: 4px; 
echo             cursor: pointer; 
echo             font-size: 15px; 
echo             margin: 10px 0; 
echo         }
echo         .browse-btn:hover { 
echo             background: #0069d9; 
echo         }
echo         .browse-btn:disabled { 
echo             background: #ccc; 
echo             cursor: not-allowed; 
echo         }
echo         #file-input { 
echo             display: none; 
echo         }
echo         .file-info { 
echo             background: #f9f9f9; 
echo             padding: 10px; 
echo             border-radius: 4px; 
echo             margin: 15px 0; 
echo             display: none; 
echo             font-size: 14px;
echo         }
echo         .progress-container { 
echo             background: #e9ecef; 
echo             border-radius: 4px; 
echo             height: 15px; 
echo             margin: 20px 0; 
echo             display: none; 
echo         }
echo         .progress-bar { 
echo             background: #007bff; 
echo             height: 100%%; 
echo             border-radius: 4px; 
echo             width: 0%%; 
echo         }
echo         .result-area { 
echo             display: none; 
echo             margin-top: 20px; 
echo         }
echo         .download-btn { 
echo             display: inline-block; 
echo             background: #28a745; 
echo             color: white; 
echo             padding: 8px 16px; 
echo             border-radius: 4px; 
echo             text-decoration: none; 
echo             margin: 5px; 
echo         }
echo         .download-btn:hover { 
echo             background: #218838; 
echo         }
echo         .status-text { 
echo             margin: 10px 0; 
echo             font-size: 14px; 
echo             color: #666; 
echo         }
echo         .preview-section {
echo             display: none;
echo             margin-top: 20px;
echo             padding: 15px;
echo             border: 1px solid #eee;
echo             border-radius: 4px;
echo             background: #f9f9f9;
echo         }
echo         .preview-title {
echo             font-weight: bold;
echo             margin-bottom: 10px;
echo             color: #333;
echo         }
echo         .page-info {
echo             text-align: left;
echo             margin: 5px 0;
echo             padding: 5px;
echo             background: white;
echo             border-radius: 3px;
echo             font-size: 13px;
echo         }
echo         .page-range {
echo             display: inline-block;
echo             margin: 0 5px;
echo         }
echo     ^</style^>
echo ^</head^>
echo ^<body^>
echo     ^<div class="container"^>
echo         ^<h1^>📄 手动双面助手^</h1^>
echo         ^<p class="subtitle"^>上传PDF文件，自动分离奇偶页并逆序排列^</p^>
echo         
echo         ^<div class="upload-area" id="upload-area"^>
echo             ^<div class="upload-icon"^>📤^</div^>
echo             ^<h3^>拖放PDF文件或点击选择^</h3^>
echo             ^<p^>最大支持500MB的PDF文件^</p^>
echo             ^<button class="browse-btn" id="browse-btn"^>选择文件^</button^>
echo             ^<input type="file" id="file-input" accept=".pdf"^>
echo         ^</div^>
echo         
echo         ^<div class="file-info" id="file-info"^>
echo             ^<strong^>已选择文件:^</strong^>
echo             ^<span id="file-name"^>^</span^>
echo             ^<span id="file-size"^>^</span^>
echo         ^</div^>
echo         
echo         ^<div class="progress-container" id="progress-container"^>
echo             ^<div class="progress-bar" id="progress-bar"^>^</div^>
echo         ^</div^>
echo         ^<div class="status-text" id="status-text"^>准备就绪^</div^>
echo         
echo         ^<button class="browse-btn" id="process-btn" disabled^>开始处理^</button^>
echo         
echo         ^<div class="preview-section" id="preview-section"^>
echo             ^<div class="preview-title"^>页码信息预览^</div^>
echo             ^<div id="page-info-content"^>^</div^>
echo         ^</div^>
echo         
echo         ^<div class="result-area" id="result-area"^>
echo             ^<h3^>✅ 处理完成！^</h3^>
echo             ^<div class="status-text" id="result-info"^>^</div^>
echo             ^<div^>
echo                 ^<a href="#" class="download-btn" id="download-odd"^>下载奇数页.pdf^</a^>
echo                 ^<a href="#" class="download-btn" id="download-even"^>下载偶数页.pdf^</a^>
echo             ^</div^>
echo         ^</div^>
echo     ^</div^>

echo     ^<script^>
echo         document.addEventListener('DOMContentLoaded', function() {
echo             const fileInput = document.getElementById('file-input');
echo             const uploadArea = document.getElementById('upload-area');
echo             const browseBtn = document.getElementById('browse-btn');
echo             const processBtn = document.getElementById('process-btn');
echo             const fileInfo = document.getElementById('file-info');
echo             const fileName = document.getElementById('file-name');
echo             const fileSize = document.getElementById('file-size');
echo             const progressContainer = document.getElementById('progress-container');
echo             const progressBar = document.getElementById('progress-bar');
echo             const statusText = document.getElementById('status-text');
echo             const resultArea = document.getElementById('result-area');
echo             const resultInfo = document.getElementById('result-info');
echo             const downloadOdd = document.getElementById('download-odd');
echo             const downloadEven = document.getElementById('download-even');
echo             const previewSection = document.getElementById('preview-section');
echo             const pageInfoContent = document.getElementById('page-info-content');
            
echo             let selectedFile = null;
echo             let currentTaskId = null;
            
echo             // 文件选择处理
echo             browseBtn.addEventListener('click', () => fileInput.click());
echo             uploadArea.addEventListener('click', (e) => {
echo                 if (e.target !== browseBtn) fileInput.click();
echo             });
            
echo             // 拖放功能
echo             uploadArea.addEventListener('dragover', (e) => {
echo                 e.preventDefault();
echo                 uploadArea.style.borderColor = '#007bff';
echo             });
            
echo             uploadArea.addEventListener('dragleave', () => {
echo                 uploadArea.style.borderColor = '#ccc';
echo             });
            
echo             uploadArea.addEventListener('drop', (e) => {
echo                 e.preventDefault();
echo                 uploadArea.style.borderColor = '#ccc';
echo                 if (e.dataTransfer.files.length) {
echo                     handleFileSelect(e.dataTransfer.files[0]);
echo                 }
echo             });
            
echo             fileInput.addEventListener('change', () => {
echo                 if (fileInput.files.length) {
echo                     handleFileSelect(fileInput.files[0]);
echo                 }
echo             });
            
echo             function handleFileSelect(file) {
echo                 if (!file.type.includes('pdf')) {
echo                     alert('请选择PDF文件！');
echo                     return;
echo                 }
                
echo                 if (file.size > 500 * 1024 * 1024) {
echo                     alert('文件大小不能超过500MB！');
echo                     return;
echo                 }
                
echo                 selectedFile = file;
echo                 fileName.textContent = file.name;
echo                 fileSize.textContent = ' (' + (file.size / 1024 / 1024).toFixed(2) + ' MB)';
echo                 fileInfo.style.display = 'block';
echo                 processBtn.disabled = false;
echo                 resultArea.style.display = 'none';
echo                 previewSection.style.display = 'none';
echo                 statusText.textContent = '文件已选择，点击开始处理';
echo             }
            
echo             // 处理按钮点击事件
echo             processBtn.addEventListener('click', async () => {
echo                 if (!selectedFile) return;
                
echo                 const formData = new FormData();
echo                 formData.append('file', selectedFile);
                
echo                 processBtn.disabled = true;
echo                 processBtn.textContent = '处理中...';
echo                 progressContainer.style.display = 'block';
echo                 statusText.textContent = '开始处理PDF文件...';
                
echo                 try {
echo                     // 上传文件并开始处理，带上传进度
echo                     const xhr = new XMLHttpRequest();
                    
echo                     // 监听上传进度
echo                     xhr.upload.addEventListener('progress', (e) => {
echo                         if (e.lengthComputable) {
echo                             const percentComplete = (e.loaded / e.total) * 100;
echo                             progressBar.style.width = percentComplete + '%%';
echo                             statusText.textContent = \`上传中: \${Math.round(percentComplete)}%%\`;
echo                         }
echo                     });
                    
echo                     // 处理响应
echo                     xhr.addEventListener('load', () => {
echo                         if (xhr.status === 200) {
echo                             const data = JSON.parse(xhr.responseText);
echo                             if (data.success) {
echo                                 currentTaskId = data.task_id;
echo                                 statusText.textContent = '文件上传成功，开始处理...';
                                
echo                                 // 显示页面预览
echo                                 showPagePreview(data.total_pages, Math.ceil(data.total_pages/2), Math.floor(data.total_pages/2));
                                
echo                                 checkProgress();
echo                             } else {
echo                                 throw new Error(data.error || '处理失败');
echo                             }
echo                         } else {
echo                             throw new Error('上传失败: ' + xhr.statusText);
echo                         }
echo                     });
                    
echo                     // 处理错误
echo                     xhr.addEventListener('error', () => {
echo                         statusText.textContent = '上传错误，请重试';
echo                         processBtn.disabled = false;
echo                         processBtn.textContent = '开始处理';
echo                     });
                    
echo                     // 开始上传
echo                     xhr.open('POST', '/process');
echo                     xhr.send(formData);
                    
echo                 } catch (error) {
echo                     statusText.textContent = '错误: ' + error.message;
echo                     processBtn.disabled = false;
echo                     processBtn.textContent = '开始处理';
echo                 }
echo             });
            
echo             // 检查处理进度
echo             function checkProgress() {
echo                 const checkInterval = setInterval(async () => {
echo                     try {
echo                         const response = await fetch('/progress');
echo                         const data = await response.json();
                        
echo                         if (data.status === 'processing') {
echo                             const progress = (data.current / data.total) * 100;
echo                             progressBar.style.width = progress + '%%';
echo                             statusText.textContent = \`处理中: \${data.current}/\${data.total} 页 (\${Math.round(progress)}%%)\`;
echo                         } else if (data.status === 'completed') {
echo                             clearInterval(checkInterval);
echo                             progressBar.style.width = '100%%';
echo                             statusText.textContent = '处理完成！';
                            
echo                             // 显示结果
echo                             resultInfo.textContent = 
echo                                 \`总共 \${data.total_pages} 页，拆分出奇数页 \${data.odd_pages} 页，偶数页 \${data.even_pages} 页\`;
echo                             downloadOdd.href = \`/download/odd?task_id=\${currentTaskId}\`;
echo                             downloadEven.href = \`/download/even?task_id=\${currentTaskId}\`;
echo                             resultArea.style.display = 'block';
                            
echo                             processBtn.textContent = '开始处理';
echo                         } else if (data.status === 'error') {
echo                             clearInterval(checkInterval);
echo                             statusText.textContent = '处理错误: ' + data.message;
echo                             processBtn.disabled = false;
echo                             processBtn.textContent = '开始处理';
echo                         }
echo                     } catch (error) {
echo                         console.error('检查进度错误:', error);
echo                     }
echo                 }, 500);
echo             }
            
echo             // 显示页码预览
echo             function showPagePreview(totalPages, oddPages, evenPages) {
echo                 pageInfoContent.innerHTML = '';
                
echo                 // 添加页面范围信息
echo                 const oddRange = document.createElement('div');
echo                 oddRange.className = 'page-info';
echo                 oddRange.innerHTML = '^<strong^>奇数页:^</strong^> ^<span class="page-range"^>共 ' + oddPages + ' 页^</span^> (逆序排列)';
                
echo                 const evenRange = document.createElement('div');
echo                 evenRange.className = 'page-info';
echo                 evenRange.innerHTML = '^<strong^>偶数页:^</strong^> ^<span class="page-range"^>共 ' + evenPages + ' 页^</span^> (逆序排列)';
                
echo                 const totalInfo = document.createElement('div');
echo                 totalInfo.className = 'page-info';
echo                 totalInfo.innerHTML = '^<strong^>原始文件:^</strong^> ^<span class="page-range"^>共 ' + totalPages + ' 页^</span^>';
                
echo                 pageInfoContent.appendChild(totalInfo);
echo                 pageInfoContent.appendChild(oddRange);
echo                 pageInfoContent.appendChild(evenRange);
                
echo                 // 显示预览区域
echo                 previewSection.style.display = 'block';
echo             }
echo         });
echo     ^</script^>
echo ^</body^>
echo ^</html^>
echo '''

echo @app.route('/')
echo def index():
echo     """主页面"""
echo     return render_template_string(HTML_TEMPLATE)

echo # 存储上传的PDF信息
echo uploaded_pdfs = {}

echo @app.route('/process', methods=['POST'])
echo def process_pdf():
echo     """处理PDF文件"""
echo     try:
echo         if 'file' not in request.files:
echo             return jsonify({'success': False, 'error': '没有选择文件'})
        
echo         file = request.files['file']
echo         if file.filename == '':
echo             return jsonify({'success': False, 'error': '没有选择文件'})
        
echo         if not allowed_file(file.filename):
echo             return jsonify({'success': False, 'error': '只支持PDF文件'})
        
echo         # 保存上传的文件
echo         temp_dir = tempfile.mkdtemp()
echo         file_path = os.path.join(temp_dir, 'input.pdf')
echo         file.save(file_path)
        
echo         # 读取PDF页面数
echo         reader = PdfReader(file_path)
echo         total_pages = len(reader.pages)
        
echo         # 生成任务ID
echo         task_id = str(int(time.time()))
        
echo         # 存储上传的PDF信息
echo         uploaded_pdfs[task_id] = {
echo             'file_path': file_path,
echo             'total_pages': total_pages
echo         }
        
echo         # 在后台线程中处理PDF
echo         thread = threading.Thread(target=process_pdf_async, args=(file_path, task_id))
echo         thread.daemon = True
echo         thread.start()
        
echo         return jsonify({
echo             'success': True, 
echo             'task_id': task_id,
echo             'total_pages': total_pages
echo         })
        
echo     except Exception as e:
echo         return jsonify({'success': False, 'error': str(e)})

echo @app.route('/preview_info/<task_id>')
echo def preview_info(task_id):
echo     """获取上传文件的页面信息"""
echo     try:
echo         if task_id in uploaded_pdfs:
echo             pdf_info = uploaded_pdfs[task_id]
echo             total_pages = pdf_info['total_pages']
            
echo             # 计算奇偶页数
echo             odd_pages = (total_pages + 1) // 2  # 奇数页数量
echo             even_pages = total_pages // 2       # 偶数页数量
            
echo             return jsonify({
echo                 "success": True,
echo                 "total_pages": total_pages,
echo                 "odd_pages": odd_pages,
echo                 "even_pages": even_pages
echo             })
echo         else:
echo             return jsonify({"success": False, "error": "未找到文件信息"}), 404
echo     except Exception as e:
echo         return jsonify({"success": False, "error": str(e)}), 500

echo @app.route('/progress')
echo def get_progress():
echo     """获取处理进度"""
echo     return jsonify(processing_progress)

echo @app.route('/download/odd')
echo def download_odd():
echo     """下载奇数页PDF"""
echo     try:
echo         if processing_progress.get("status") == "completed":
echo             file_path = processing_progress["result"]["odd_path"]
echo             return send_file(file_path, as_attachment=True, download_name='奇数页.pdf')
echo         else:
echo             return "文件不存在或已过期", 404
echo     except Exception as e:
echo         return str(e), 500

echo @app.route('/download/even')
echo def download_even():
echo     """下载偶数页PDF"""
echo     try:
echo         if processing_progress.get("status") == "completed":
echo             file_path = processing_progress["result"]["even_path"]
echo             return send_file(file_path, as_attachment=True, download_name='偶数页.pdf')
echo         else:
echo             return "文件不存在或已过期", 404
echo     except Exception as e:
echo         return str(e), 500

echo @app.route('/preview')
echo def preview_pdf():
echo     """获取PDF预览信息"""
echo     try:
echo         if processing_progress.get("status") == "completed":
echo             result = processing_progress["result"]
echo             return jsonify({
echo                 "success": True,
echo                 "total_pages": result["total_pages"],
echo                 "odd_pages": result["odd_pages"],
echo                 "even_pages": result["even_pages"]
echo             })
echo         else:
echo             return jsonify({"success": False, "error": "处理未完成"}), 400
echo     except Exception as e:
echo         return jsonify({"success": False, "error": str(e)}), 500

echo def open_browser():
echo     """启动后自动打开浏览器"""
echo     import subprocess
echo     subprocess.run(["start", "http://127.0.0.1:5000"], shell=True)

echo if __name__ == '__main__':
echo     # 延迟1秒后打开浏览器
echo     Timer(1, open_browser).start()
echo     # 启动Flask应用
echo     app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)
) > print_helper.py

REM 安装Python模块
echo 安装所需的Python模块...
python -m pip install flask PyPDF2

echo 所有配置完成！
echo 运行以下命令启动应用：
echo python print_helper.py

pause
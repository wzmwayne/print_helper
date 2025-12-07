from flask import Flask, request, send_file, render_template_string, jsonify
from PyPDF2 import PdfReader, PdfWriter
import os
import tempfile
import threading
import time
import webbrowser
from threading import Timer
from PIL import Image
import fitz  # PyMuPDF
import docx
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.utils import ImageReader
import io

app = Flask(__name__)

# 全局变量用于存储处理进度
processing_progress = {"current": 0, "total": 0, "status": "ready"}

def convert_to_pdf(file_path, output_path):
    """将各种文件格式转换为PDF"""
    try:
        file_ext = os.path.splitext(file_path)[1].lower()
        
        if file_ext == '.pdf':
            # 已经是PDF，直接复制
            import shutil
            shutil.copy2(file_path, output_path)
            return True
            
        elif file_ext in ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp']:
            # 图片转PDF
            img = Image.open(file_path)
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            # 计算适合的页面大小
            img_width, img_height = img.size
            page_width, page_height = A4
            
            # 如果图片太大，缩放到适合页面
            if img_width > page_width or img_height > page_height:
                ratio = min(page_width / img_width, page_height / img_height)
                new_width = int(img_width * ratio)
                new_height = int(img_height * ratio)
                img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
                img_width, img_height = new_width, new_height
            
            # 创建PDF
            c = canvas.Canvas(output_path, pagesize=A4)
            
            # 居中放置图片
            x = (page_width - img_width) / 2
            y = (page_height - img_height) / 2
            c.drawImage(ImageReader(img), x, y, img_width, img_height)
            c.save()
            return True
            
        elif file_ext == '.docx':
            # Word文档转PDF
            doc = docx.Document(file_path)
            c = canvas.Canvas(output_path, pagesize=A4)
            page_width, page_height = A4
            margin = 50
            y_position = page_height - margin
            line_height = 14
            
            for paragraph in doc.paragraphs:
                text = paragraph.text
                if not text.strip():
                    y_position -= line_height
                    continue
                    
                # 分行处理
                words = text.split()
                line = ""
                for word in words:
                    test_line = line + word + " "
                    if c.stringWidth(test_line, "Helvetica", 12) < page_width - 2 * margin:
                        line = test_line
                    else:
                        if line:
                            c.drawString(margin, y_position, line.strip())
                            y_position -= line_height
                        line = word + " "
                        
                        if y_position < margin:
                            c.showPage()
                            y_position = page_height - margin
                
                if line:
                    c.drawString(margin, y_position, line.strip())
                    y_position -= line_height
                    
                if y_position < margin:
                    c.showPage()
                    y_position = page_height - margin
                    
                y_position -= line_height // 2  # 段落间距
                
                if y_position < margin:
                    c.showPage()
                    y_position = page_height - margin
            
            c.save()
            return True
            
        elif file_ext in ['.txt', '.md', '.html', '.htm', '.odt']:
            # 文本文件转PDF
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                text = f.read()
            
            c = canvas.Canvas(output_path, pagesize=A4)
            page_width, page_height = A4
            margin = 50
            y_position = page_height - margin
            line_height = 14
            
            lines = text.split('\n')
            for line in lines:
                # 分行长行
                words = line.split()
                current_line = ""
                for word in words:
                    test_line = current_line + word + " "
                    if c.stringWidth(test_line, "Helvetica", 12) < page_width - 2 * margin:
                        current_line = test_line
                    else:
                        if current_line:
                            c.drawString(margin, y_position, current_line.strip())
                            y_position -= line_height
                        current_line = word + " "
                        
                        if y_position < margin:
                            c.showPage()
                            y_position = page_height - margin
                
                if current_line:
                    c.drawString(margin, y_position, current_line.strip())
                    y_position -= line_height
                    
                if y_position < margin:
                    c.showPage()
                    y_position = page_height - margin
                
                y_position -= line_height // 2  # 行间距
                
                if y_position < margin:
                    c.showPage()
                    y_position = page_height - margin
            
            c.save()
            return True
            
        else:
            # 尝试使用PyMuPDF处理其他格式
            try:
                doc = fitz.open(file_path)
                pdf_bytes = doc.convert_to_pdf()
                with open(output_path, 'wb') as f:
                    f.write(pdf_bytes)
                doc.close()
                return True
            except:
                return False
                
    except Exception as e:
        print(f"转换错误: {str(e)}")
        return False

def allowed_file(filename):
    """检查文件类型"""
    if not '.' in filename:
        return False
    
    # 支持的文件类型
    supported_extensions = {
        # 文档类型
        '.pdf', '.doc', '.docx', '.txt', '.rtf',
        # 图片类型
        '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp',
        # 其他格式
        '.html', '.htm', '.md', '.odt', '.ods', '.odp'
    }
    
    return filename.lower().endswith(tuple(supported_extensions))

def process_pdf_async(file_path, task_id):
    """异步处理文件，转换为PDF后分离奇偶页"""
    try:
        processing_progress["phase"] = "processing"
        processing_progress["status"] = "processing"
        processing_progress["current"] = 0
        processing_progress["message"] = "正在转换文件格式..."
        
        # 创建临时目录
        temp_dir = tempfile.mkdtemp()
        pdf_path = os.path.join(temp_dir, 'converted.pdf')
        
        # 转换文件为PDF
        if not convert_to_pdf(file_path, pdf_path):
            processing_progress["status"] = "error"
            processing_progress["message"] = "文件转换失败，不支持此格式"
            processing_progress["phase"] = "error"
            return
        
        processing_progress["message"] = "正在处理PDF页面..."
        
        # 读取转换后的PDF文件
        reader = PdfReader(pdf_path)
        total_pages = len(reader.pages)
        processing_progress["total"] = total_pages
        
        if total_pages == 0:
            processing_progress["status"] = "error"
            processing_progress["message"] = "转换后的PDF文件没有页面内容"
            processing_progress["phase"] = "error"
            return
        
        # 创建临时目录存储结果
        temp_dir = tempfile.mkdtemp()
        odd_path = os.path.join(temp_dir, '奇数页.pdf')
        even_path = os.path.join(temp_dir, '偶数页.pdf')
        
        # 处理奇数页（逆序）
        odd_writer = PdfWriter()
        odd_pages = []
        
        # 收集奇数页（索引从0开始，索引0=第1页是奇数页）
        for i in range(total_pages-1, -1, -1):
            if i % 2 == 0:  # 索引为偶数的页面是奇数页
                odd_pages.append(i)
            processing_progress["current"] = total_pages - i
            time.sleep(0.01)  # 稍微延迟以便显示进度
        
        # 添加奇数页到输出
        for page_num in odd_pages:
            odd_writer.add_page(reader.pages[page_num])
        
        # 保存奇数页PDF
        with open(odd_path, 'wb') as odd_file:
            odd_writer.write(odd_file)
        
        processing_progress["current"] = total_pages // 2
        
        # 处理偶数页（逆序）
        even_writer = PdfWriter()
        even_pages = []
        
        # 收集偶数页（索引从0开始，索引1=第2页是偶数页）
        for i in range(total_pages-1, -1, -1):
            if i % 2 == 1:  # 索引为奇数的页面是偶数页
                even_pages.append(i)
        
        # 添加偶数页到输出
        for page_num in even_pages:
            even_writer.add_page(reader.pages[page_num])
        
        # 保存偶数页PDF
        with open(even_path, 'wb') as even_file:
            even_writer.write(even_file)
        
        processing_progress["current"] = total_pages
        processing_progress["status"] = "completed"
        processing_progress["phase"] = "completed"
        processing_progress["result"] = {
            "odd_path": odd_path,
            "even_path": even_path,
            "total_pages": total_pages,
            "odd_pages": len(odd_pages),
            "even_pages": len(even_pages),
            "file_path": file_path,  # 保存原始文件路径用于预览
            "converted_pdf": pdf_path  # 保存转换后的PDF路径
        }
        
    except Exception as e:
        processing_progress["status"] = "error"
        processing_progress["message"] = str(e)

# HTML模板（极简设计，添加页码和预览功能）
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>手动双面助手</title>
    <style>
        * { 
            margin: 0; 
            padding: 0; 
            box-sizing: border-box; 
        }
        body { 
            font-family: Arial, sans-serif; 
            background-color: #f5f5f5;
            min-height: 100vh; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            padding: 20px; 
        }
        .container { 
            background: white; 
            border-radius: 8px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
            padding: 30px; 
            width: 100%; 
            max-width: 500px; 
            text-align: center; 
        }
        h1 { 
            color: #333; 
            margin-bottom: 5px; 
            font-size: 22px; 
        }
        .subtitle { 
            color: #666; 
            margin-bottom: 25px; 
            font-size: 13px; 
        }
        .upload-area { 
            border: 2px dashed #ccc; 
            border-radius: 6px; 
            padding: 30px 20px; 
            margin: 20px 0; 
            cursor: pointer; 
        }
        .upload-icon { 
            font-size: 40px; 
            margin-bottom: 10px; 
            color: #666;
        }
        .browse-btn { 
            background: #007bff; 
            color: white; 
            border: none; 
            padding: 10px 20px; 
            border-radius: 4px; 
            cursor: pointer; 
            font-size: 15px; 
            margin: 10px 0; 
        }
        .browse-btn:hover { 
            background: #0069d9; 
        }
        .browse-btn:disabled { 
            background: #ccc; 
            cursor: not-allowed; 
        }
        #file-input { 
            display: none; 
        }
        .file-info { 
            background: #f9f9f9; 
            padding: 10px; 
            border-radius: 4px; 
            margin: 15px 0; 
            display: none; 
            font-size: 14px;
        }
        .progress-container { 
            background: #e9ecef; 
            border-radius: 4px; 
            height: 15px; 
            margin: 20px 0; 
            display: none; 
        }
        .progress-bar { 
            background: #007bff; 
            height: 100%; 
            border-radius: 4px; 
            width: 0%; 
        }
        .result-area { 
            display: none; 
            margin-top: 20px; 
        }
        .download-btn { 
            display: inline-block; 
            background: #28a745; 
            color: white; 
            padding: 8px 16px; 
            border-radius: 4px; 
            text-decoration: none; 
            margin: 5px; 
        }
        .download-btn:hover { 
            background: #218838; 
        }
        .status-text { 
            margin: 10px 0; 
            font-size: 14px; 
            color: #666; 
        }
        .preview-section {
            display: none;
            margin-top: 20px;
            padding: 15px;
            border: 1px solid #eee;
            border-radius: 4px;
            background: #f9f9f9;
        }
        .preview-title {
            font-weight: bold;
            margin-bottom: 10px;
            color: #333;
        }
        .page-info {
            text-align: left;
            margin: 5px 0;
            padding: 5px;
            background: white;
            border-radius: 3px;
            font-size: 13px;
        }
        .page-range {
            display: inline-block;
            margin: 0 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📄 手动双面助手</h1>
        <p class="subtitle">上传文件（PDF/图片/文档），自动转换为PDF并分离奇偶页</p>
        
        <div class="upload-area" id="upload-area">
            <div class="upload-icon">📤</div>
            <h3>拖放文件或点击选择</h3>
            <p>支持PDF、图片(JPG/PNG/GIF等)、文档(Word/TXT等)，最大500MB</p>
            <button class="browse-btn" id="browse-btn">选择文件</button>
            <input type="file" id="file-input" accept=".pdf,.jpg,.jpeg,.png,.gif,.bmp,.tiff,.webp,.doc,.docx,.txt,.rtf,.html,.htm,.md,.odt,.ods,.odp">
        </div>
        
        <div class="file-info" id="file-info">
            <strong>已选择文件:</strong>
            <span id="file-name"></span>
            <span id="file-size"></span>
        </div>
        
        <div class="progress-container" id="progress-container">
            <div class="progress-bar" id="progress-bar"></div>
        </div>
        <div class="status-text" id="status-text">准备就绪</div>
        
        <button class="browse-btn" id="process-btn" disabled>开始处理</button>
        
        <div class="preview-section" id="preview-section">
            <div class="preview-title">页码信息预览</div>
            <div id="page-info-content"></div>
        </div>
        
        <div class="result-area" id="result-area">
            <h3>✅ 处理完成！</h3>
            <div class="status-text" id="result-info"></div>
            <div>
                <a href="#" class="download-btn" id="download-odd">下载奇数页.pdf</a>
                <a href="#" class="download-btn" id="download-even">下载偶数页.pdf</a>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const fileInput = document.getElementById('file-input');
            const uploadArea = document.getElementById('upload-area');
            const browseBtn = document.getElementById('browse-btn');
            const processBtn = document.getElementById('process-btn');
            const fileInfo = document.getElementById('file-info');
            const fileName = document.getElementById('file-name');
            const fileSize = document.getElementById('file-size');
            const progressContainer = document.getElementById('progress-container');
            const progressBar = document.getElementById('progress-bar');
            const statusText = document.getElementById('status-text');
            const resultArea = document.getElementById('result-area');
            const resultInfo = document.getElementById('result-info');
            const downloadOdd = document.getElementById('download-odd');
            const downloadEven = document.getElementById('download-even');
            const previewSection = document.getElementById('preview-section');
            const pageInfoContent = document.getElementById('page-info-content');
            
            let selectedFile = null;
            let currentTaskId = null;
            
            // 文件选择处理
            browseBtn.addEventListener('click', () => fileInput.click());
            uploadArea.addEventListener('click', (e) => {
                if (e.target !== browseBtn) fileInput.click();
            });
            
            // 拖放功能
            uploadArea.addEventListener('dragover', (e) => {
                e.preventDefault();
                uploadArea.style.borderColor = '#007bff';
            });
            
            uploadArea.addEventListener('dragleave', () => {
                uploadArea.style.borderColor = '#ccc';
            });
            
            uploadArea.addEventListener('drop', (e) => {
                e.preventDefault();
                uploadArea.style.borderColor = '#ccc';
                if (e.dataTransfer.files.length) {
                    handleFileSelect(e.dataTransfer.files[0]);
                }
            });
            
            fileInput.addEventListener('change', () => {
                if (fileInput.files.length) {
                    handleFileSelect(fileInput.files[0]);
                }
            });
            
            function handleFileSelect(file) {
                // 检查文件大小
                if (file.size > 500 * 1024 * 1024) {
                    alert('文件大小不能超过500MB！');
                    return;
                }
                
                // 检查文件类型
                const fileName = file.name.toLowerCase();
                const supportedTypes = [
                    '.pdf', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp',
                    '.doc', '.docx', '.txt', '.rtf', '.html', '.htm', '.md', '.odt', '.ods', '.odp'
                ];
                
                let isSupported = false;
                for (let type of supportedTypes) {
                    if (fileName.endsWith(type)) {
                        isSupported = true;
                        break;
                    }
                }
                
                if (!isSupported) {
                    alert('不支持的文件类型！请选择PDF、图片或文档文件。');
                    return;
                }
                
                selectedFile = file;
                fileName.textContent = file.name;
                fileSize.textContent = ' (' + (file.size / 1024 / 1024).toFixed(2) + ' MB)';
                fileInfo.style.display = 'block';
                processBtn.disabled = false;
                resultArea.style.display = 'none';
                previewSection.style.display = 'none';
                statusText.textContent = '文件已选择，点击开始处理';
            }
            
            // 处理按钮点击事件
            processBtn.addEventListener('click', async () => {
                if (!selectedFile) return;
                
                const formData = new FormData();
                formData.append('file', selectedFile);
                
                processBtn.disabled = true;
                processBtn.textContent = '处理中...';
                progressContainer.style.display = 'block';
                statusText.textContent = '开始处理文件...';
                
                try {
                    // 上传文件并开始处理，带上传进度
                    const xhr = new XMLHttpRequest();
                    
                    // 监听上传进度
                    xhr.upload.addEventListener('progress', (e) => {
                        if (e.lengthComputable) {
                            const percentComplete = (e.loaded / e.total) * 100;
                            progressBar.style.width = percentComplete + '%';
                            statusText.textContent = `上传中: ${Math.round(percentComplete)}%`;
                        }
                    });
                    
                    // 处理响应
                    xhr.addEventListener('load', () => {
                        if (xhr.status === 200) {
                            const data = JSON.parse(xhr.responseText);
                            if (data.success) {
                                currentTaskId = data.task_id;
                                statusText.textContent = '文件上传成功，正在转换为PDF并处理...';
                                
                                // 显示页面预览
                                showPagePreview(data.total_pages, Math.ceil(data.total_pages/2), Math.floor(data.total_pages/2));
                                
                                checkProgress();
                            } else {
                                throw new Error(data.error || '处理失败');
                            }
                        } else {
                            throw new Error('上传失败: ' + xhr.statusText);
                        }
                    });
                    
                    // 处理错误
                    xhr.addEventListener('error', () => {
                        statusText.textContent = '上传错误，请重试';
                        processBtn.disabled = false;
                        processBtn.textContent = '开始处理';
                    });
                    
                    // 开始上传
                    xhr.open('POST', '/process');
                    xhr.send(formData);
                    
                } catch (error) {
                    statusText.textContent = '错误: ' + error.message;
                    processBtn.disabled = false;
                    processBtn.textContent = '开始处理';
                }
            });
            
            // 检查处理进度
            function checkProgress() {
                const checkInterval = setInterval(async () => {
                    try {
                        const response = await fetch('/progress');
                        const data = await response.json();
                        
                        if (data.status === 'processing') {
                            const progress = (data.current / data.total) * 100;
                            progressBar.style.width = progress + '%';
                            statusText.textContent = `处理中: ${data.current}/${data.total} 页 (${Math.round(progress)}%)`;
                        } else if (data.status === 'completed') {
                            clearInterval(checkInterval);
                            progressBar.style.width = '100%';
                            statusText.textContent = '处理完成！';
                            
                            // 显示结果
                            resultInfo.textContent = 
                                `总共 ${data.total_pages} 页，拆分出奇数页 ${data.odd_pages} 页，偶数页 ${data.even_pages} 页`;
                            downloadOdd.href = `/download/odd?task_id=${currentTaskId}`;
                            downloadEven.href = `/download/even?task_id=${currentTaskId}`;
                            resultArea.style.display = 'block';
                            
                            processBtn.textContent = '开始处理';
                        } else if (data.status === 'error') {
                            clearInterval(checkInterval);
                            statusText.textContent = '处理错误: ' + data.message;
                            processBtn.disabled = false;
                            processBtn.textContent = '开始处理';
                        }
                    } catch (error) {
                        console.error('检查进度错误:', error);
                    }
                }, 500);
            }
            
            // 显示页码预览
            function showPagePreview(totalPages, oddPages, evenPages) {
                pageInfoContent.innerHTML = '';
                
                // 添加页面范围信息
                const oddRange = document.createElement('div');
                oddRange.className = 'page-info';
                oddRange.innerHTML = '<strong>奇数页:</strong> <span class="page-range">共 ' + oddPages + ' 页</span> (逆序排列)';
                
                const evenRange = document.createElement('div');
                evenRange.className = 'page-info';
                evenRange.innerHTML = '<strong>偶数页:</strong> <span class="page-range">共 ' + evenPages + ' 页</span> (逆序排列)';
                
                const totalInfo = document.createElement('div');
                totalInfo.className = 'page-info';
                totalInfo.innerHTML = '<strong>原始文件:</strong> <span class="page-range">共 ' + totalPages + ' 页</span>';
                
                pageInfoContent.appendChild(totalInfo);
                pageInfoContent.appendChild(oddRange);
                pageInfoContent.appendChild(evenRange);
                
                // 显示预览区域
                previewSection.style.display = 'block';
            }
        });
    </script>
</body>
</html>
'''

@app.route('/')
def index():
    """主页面"""
    return render_template_string(HTML_TEMPLATE)

# 存储上传的PDF信息
uploaded_pdfs = {}

@app.route('/process', methods=['POST'])
def process_pdf():
    """处理PDF文件"""
    try:
        if 'file' not in request.files:
            return jsonify({'success': False, 'error': '没有选择文件'})
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'success': False, 'error': '没有选择文件'})
        
        if not allowed_file(file.filename):
            return jsonify({'success': False, 'error': '不支持的文件类型'})
        
        # 保存上传的文件
        temp_dir = tempfile.mkdtemp()
        file_path = os.path.join(temp_dir, 'input.pdf')
        file.save(file_path)
        
        # 读取PDF页面数
        reader = PdfReader(file_path)
        total_pages = len(reader.pages)
        
        # 生成任务ID
        task_id = str(int(time.time()))
        
        # 存储上传的PDF信息
        uploaded_pdfs[task_id] = {
            'file_path': file_path,
            'total_pages': total_pages
        }
        
        # 在后台线程中处理PDF
        thread = threading.Thread(target=process_pdf_async, args=(file_path, task_id))
        thread.daemon = True
        thread.start()
        
        return jsonify({
            'success': True, 
            'task_id': task_id,
            'total_pages': total_pages
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/preview_info/<task_id>')
def preview_info(task_id):
    """获取上传文件的页面信息"""
    try:
        if task_id in uploaded_pdfs:
            pdf_info = uploaded_pdfs[task_id]
            total_pages = pdf_info['total_pages']
            
            # 计算奇偶页数
            odd_pages = (total_pages + 1) // 2  # 奇数页数量
            even_pages = total_pages // 2       # 偶数页数量
            
            return jsonify({
                "success": True,
                "total_pages": total_pages,
                "odd_pages": odd_pages,
                "even_pages": even_pages
            })
        else:
            return jsonify({"success": False, "error": "未找到文件信息"}), 404
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/progress')
def get_progress():
    """获取处理进度"""
    return jsonify(processing_progress)

@app.route('/download/odd')
def download_odd():
    """下载奇数页PDF"""
    try:
        if processing_progress.get("status") == "completed":
            file_path = processing_progress["result"]["odd_path"]
            return send_file(file_path, as_attachment=True, download_name='奇数页.pdf')
        else:
            return "文件不存在或已过期", 404
    except Exception as e:
        return str(e), 500

@app.route('/download/even')
def download_even():
    """下载偶数页PDF"""
    try:
        if processing_progress.get("status") == "completed":
            file_path = processing_progress["result"]["even_path"]
            return send_file(file_path, as_attachment=True, download_name='偶数页.pdf')
        else:
            return "文件不存在或已过期", 404
    except Exception as e:
        return str(e), 500

@app.route('/preview')
def preview_pdf():
    """获取PDF预览信息"""
    try:
        if processing_progress.get("status") == "completed":
            result = processing_progress["result"]
            return jsonify({
                "success": True,
                "total_pages": result["total_pages"],
                "odd_pages": result["odd_pages"],
                "even_pages": result["even_pages"]
            })
        else:
            return jsonify({"success": False, "error": "处理未完成"}), 400
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

def open_browser():
    """启动后自动打开浏览器"""
    webbrowser.open('http://127.0.0.1:5000')

if __name__ == '__main__':
    # 延迟1秒后打开浏览器
    Timer(1, open_browser).start()
    # 启动Flask应用
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)

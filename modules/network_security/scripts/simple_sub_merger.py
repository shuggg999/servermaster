#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import json
import base64
import urllib.request
import urllib.parse
import re
import time
import socket
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import threading
import argparse
from pathlib import Path

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("/var/log/sub_merger.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("SubMerger")

# 配置目录
CONFIG_DIR = "/opt/sub_merger"
SUBSCRIPTIONS_FILE = os.path.join(CONFIG_DIR, "subscriptions.json")
ACCESS_TOKEN_FILE = os.path.join(CONFIG_DIR, "access_token.txt")
PORT_FILE = os.path.join(CONFIG_DIR, "port.txt")
DEFAULT_PORT = 25500
DEFAULT_TOKEN = "554365"

# 确保配置目录存在
os.makedirs(CONFIG_DIR, exist_ok=True)

# 读取或创建订阅文件
def load_subscriptions():
    if os.path.exists(SUBSCRIPTIONS_FILE):
        try:
            with open(SUBSCRIPTIONS_FILE, 'r') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"读取订阅文件失败: {e}")
            return []
    else:
        return []

# 保存订阅
def save_subscriptions(subscriptions):
    try:
        with open(SUBSCRIPTIONS_FILE, 'w') as f:
            json.dump(subscriptions, f, indent=2)
        return True
    except Exception as e:
        logger.error(f"保存订阅文件失败: {e}")
        return False

# 读取访问令牌
def load_access_token():
    if os.path.exists(ACCESS_TOKEN_FILE):
        try:
            with open(ACCESS_TOKEN_FILE, 'r') as f:
                return f.read().strip()
        except Exception as e:
            logger.error(f"读取访问令牌失败: {e}")
            return DEFAULT_TOKEN
    else:
        # 如果文件不存在，创建默认的
        try:
            with open(ACCESS_TOKEN_FILE, 'w') as f:
                f.write(DEFAULT_TOKEN)
            return DEFAULT_TOKEN
        except Exception as e:
            logger.error(f"创建访问令牌文件失败: {e}")
            return DEFAULT_TOKEN

# 保存访问令牌
def save_access_token(token):
    try:
        with open(ACCESS_TOKEN_FILE, 'w') as f:
            f.write(token)
        return True
    except Exception as e:
        logger.error(f"保存访问令牌失败: {e}")
        return False

# 读取端口
def load_port():
    if os.path.exists(PORT_FILE):
        try:
            with open(PORT_FILE, 'r') as f:
                return int(f.read().strip())
        except Exception as e:
            logger.error(f"读取端口失败: {e}")
            return DEFAULT_PORT
    else:
        # 如果文件不存在，创建默认的
        try:
            with open(PORT_FILE, 'w') as f:
                f.write(str(DEFAULT_PORT))
            return DEFAULT_PORT
        except Exception as e:
            logger.error(f"创建端口文件失败: {e}")
            return DEFAULT_PORT

# 保存端口
def save_port(port):
    try:
        with open(PORT_FILE, 'w') as f:
            f.write(str(port))
        return True
    except Exception as e:
        logger.error(f"保存端口失败: {e}")
        return False

# 获取外部IP
def get_external_ip():
    try:
        external_ip = urllib.request.urlopen('https://api.ipify.org').read().decode('utf8')
        return external_ip
    except Exception as e:
        logger.error(f"获取外部IP失败: {e}")
        try:
            external_ip = urllib.request.urlopen('https://ifconfig.me').read().decode('utf8')
            return external_ip
        except Exception as e:
            logger.error(f"备用方法获取外部IP失败: {e}")
            # 使用socket获取本地IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            try:
                # 不需要真正连接
                s.connect(('10.255.255.255', 1))
                local_ip = s.getsockname()[0]
            except Exception:
                local_ip = '127.0.0.1'
            finally:
                s.close()
            return local_ip

# 下载订阅内容
def download_subscription(url):
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml',
        }
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as response:
            content = response.read().decode('utf-8')
            return content.strip()
    except Exception as e:
        logger.error(f"下载订阅 {url} 失败: {e}")
        return None

# 判断是否是Base64编码
def is_base64(content):
    try:
        base64_pattern = r'^[A-Za-z0-9+/]+={0,2}$'
        return bool(re.match(base64_pattern, content))
    except Exception:
        return False

# 解码订阅内容
def decode_subscription(content):
    # 如果内容已经是协议链接开头，直接返回
    if content.startswith(('vless://', 'vmess://', 'trojan://', 'ss://')):
        return content
    
    # 尝试Base64解码
    if is_base64(content):
        try:
            decoded = base64.b64decode(content).decode('utf-8')
            if decoded.startswith(('vless://', 'vmess://', 'trojan://', 'ss://')):
                return decoded
            else:
                # 可能是多行base64
                lines = decoded.strip().split('\n')
                valid_links = [line for line in lines if line.startswith(('vless://', 'vmess://', 'trojan://', 'ss://'))]
                if valid_links:
                    return '\n'.join(valid_links)
        except Exception as e:
            logger.error(f"Base64解码失败: {e}")
    
    # 如果还没有有效链接，再尝试按行解析
    lines = content.strip().split('\n')
    valid_links = []
    
    for line in lines:
        line = line.strip()
        # 直接检查是否是有效链接
        if line.startswith(('vless://', 'vmess://', 'trojan://', 'ss://')):
            valid_links.append(line)
        # 尝试作为Base64解码单行
        elif is_base64(line):
            try:
                decoded_line = base64.b64decode(line).decode('utf-8')
                if decoded_line.startswith(('vless://', 'vmess://', 'trojan://', 'ss://')):
                    valid_links.append(decoded_line)
            except Exception:
                pass
    
    if valid_links:
        return '\n'.join(valid_links)
    
    # 如果所有尝试都失败，返回原始内容
    logger.warning(f"无法解析订阅内容格式: {content[:100]}...")
    return content

# 合并订阅
def merge_subscriptions(subscription_urls):
    merged_links = []
    
    for url in subscription_urls:
        content = download_subscription(url)
        if content:
            decoded_content = decode_subscription(content)
            if decoded_content:
                # 分割多行并添加到列表
                links = decoded_content.strip().split('\n')
                merged_links.extend([link for link in links if link.strip()])
    
    # 去重
    unique_links = list(dict.fromkeys(merged_links))
    
    # 返回合并的链接
    return '\n'.join(unique_links)

# 转换为各种客户端格式
def convert_to_client_format(content, client_type):
    # 目前仅支持直接返回原始内容，未来可以扩展为不同客户端格式的转换
    if client_type.lower() in ['v2ray', 'shadowrocket', 'surge', 'clash', 'quanx']:
        # Base64编码结果，符合大多数客户端期望
        if content:
            encoded_content = base64.b64encode(content.encode('utf-8')).decode('utf-8')
            return encoded_content
    
    return content

# 生成合并的订阅链接
def generate_subscription_links(server_ip, port, token):
    base_url = f"http://{server_ip}:{port}/sub?token={token}"
    
    links = {
        "v2ray": f"{base_url}&target=v2ray",
        "clash": f"{base_url}&target=clash",
        "shadowrocket": f"{base_url}&target=shadowrocket",
        "surge": f"{base_url}&target=surge",
        "quanx": f"{base_url}&target=quanx"
    }
    
    return links

# HTTP服务器处理程序
class SubRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            # 解析路径和查询参数
            parsed_path = urllib.parse.urlparse(self.path)
            query_params = urllib.parse.parse_qs(parsed_path.query)
            
            # 检查访问令牌
            if parsed_path.path == '/sub':
                access_token = load_access_token()
                client_token = query_params.get('token', [''])[0]
                
                if client_token != access_token:
                    self.send_response(403)
                    self.send_header('Content-type', 'text/plain; charset=utf-8')
                    self.end_headers()
                    self.wfile.write("访问令牌无效".encode('utf-8'))
                    return
                
                # 获取请求的目标客户端类型
                target = query_params.get('target', ['v2ray'])[0].lower()
                
                # 处理订阅
                subscriptions = load_subscriptions()
                subscription_urls = [sub["url"] for sub in subscriptions]
                
                if not subscription_urls:
                    self.send_response(404)
                    self.send_header('Content-type', 'text/plain; charset=utf-8')
                    self.end_headers()
                    self.wfile.write("未配置订阅源".encode('utf-8'))
                    return
                
                # 合并订阅
                merged_content = merge_subscriptions(subscription_urls)
                
                # 转换为目标格式
                client_content = convert_to_client_format(merged_content, target)
                
                # 发送响应
                self.send_response(200)
                self.send_header('Content-type', 'text/plain; charset=utf-8')
                self.send_header('Subscription-Userinfo', 'upload=0; download=0; total=10737418240; expire=2147483647')
                self.end_headers()
                self.wfile.write(client_content.encode('utf-8'))
                return
            
            # 健康检查
            elif parsed_path.path == '/ping':
                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(b"pong")
                return
            
            # 404 未找到
            else:
                self.send_response(404)
                self.send_header('Content-type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write("未找到请求的资源".encode('utf-8'))
                
        except Exception as e:
            logger.error(f"处理请求失败: {e}")
            self.send_response(500)
            self.send_header('Content-type', 'text/plain; charset=utf-8')
            self.end_headers()
            self.wfile.write(f"服务器内部错误: {str(e)}".encode('utf-8'))

# 启动HTTP服务器
def run_server(port):
    server_address = ('', port)
    httpd = HTTPServer(server_address, SubRequestHandler)
    logger.info(f"HTTP服务器正在端口 {port} 上运行...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    logger.info("HTTP服务器已关闭")

# 以守护线程方式启动服务器
def start_server_thread(port):
    thread = threading.Thread(target=run_server, args=(port,), daemon=True)
    thread.start()
    return thread

# 添加订阅
def add_subscription(name, url):
    subscriptions = load_subscriptions()
    
    # 检查是否已存在
    for sub in subscriptions:
        if sub["url"] == url:
            logger.warning(f"订阅 {url} 已存在")
            return False
    
    # 测试订阅是否可用
    content = download_subscription(url)
    if not content:
        logger.error(f"无法下载订阅: {url}")
        return False
    
    decoded_content = decode_subscription(content)
    if not decoded_content or not any(decoded_content.startswith(prefix) for prefix in ['vless://', 'vmess://', 'trojan://', 'ss://']):
        logger.error(f"订阅内容格式无效: {url}")
        return False
    
    # 添加订阅
    subscriptions.append({
        "name": name,
        "url": url,
        "added_at": time.strftime("%Y-%m-%d %H:%M:%S")
    })
    
    return save_subscriptions(subscriptions)

# 删除订阅
def remove_subscription(url_or_index):
    subscriptions = load_subscriptions()
    
    if not subscriptions:
        logger.warning("没有订阅可删除")
        return False
    
    # 如果是索引
    if isinstance(url_or_index, int) and 0 <= url_or_index < len(subscriptions):
        del subscriptions[url_or_index]
        return save_subscriptions(subscriptions)
    
    # 如果是URL
    for i, sub in enumerate(subscriptions):
        if sub["url"] == url_or_index:
            del subscriptions[i]
            return save_subscriptions(subscriptions)
    
    logger.warning(f"未找到订阅: {url_or_index}")
    return False

# 列出所有订阅
def list_subscriptions():
    return load_subscriptions()

# 更新访问令牌
def update_access_token(token):
    return save_access_token(token)

# 更新端口
def update_port(port):
    return save_port(port)

# 生成所有客户端的订阅信息
def generate_all_subscription_info():
    server_ip = get_external_ip()
    port = load_port()
    token = load_access_token()
    
    links = generate_subscription_links(server_ip, port, token)
    
    info = {
        "server_ip": server_ip,
        "port": port,
        "token": token,
        "links": links,
        "subscriptions": load_subscriptions(),
    }
    
    return info

# 主函数
def main():
    parser = argparse.ArgumentParser(description='简易订阅合并工具')
    parser.add_argument('--start', action='store_true', help='启动HTTP服务器')
    parser.add_argument('--port', type=int, default=None, help='指定HTTP服务器端口')
    parser.add_argument('--add', nargs=2, metavar=('NAME', 'URL'), help='添加订阅')
    parser.add_argument('--remove', metavar='URL_OR_INDEX', help='删除订阅')
    parser.add_argument('--list', action='store_true', help='列出所有订阅')
    parser.add_argument('--token', metavar='TOKEN', help='更新访问令牌')
    parser.add_argument('--info', action='store_true', help='显示订阅信息')
    
    args = parser.parse_args()
    
    # 确保目录存在
    if not os.path.exists(CONFIG_DIR):
        os.makedirs(CONFIG_DIR)
    
    # 处理命令
    if args.start:
        port = args.port if args.port else load_port()
        run_server(port)
    elif args.add:
        success = add_subscription(args.add[0], args.add[1])
        print(f"添加订阅 {'成功' if success else '失败'}")
    elif args.remove:
        try:
            index = int(args.remove)
            success = remove_subscription(index)
        except ValueError:
            success = remove_subscription(args.remove)
        print(f"删除订阅 {'成功' if success else '失败'}")
    elif args.list:
        subs = list_subscriptions()
        if not subs:
            print("没有配置订阅")
        else:
            for i, sub in enumerate(subs):
                print(f"{i}. {sub['name']} - {sub['url']} (添加于 {sub['added_at']})")
    elif args.token:
        success = update_access_token(args.token)
        print(f"更新访问令牌 {'成功' if success else '失败'}")
    elif args.port:
        success = update_port(args.port)
        print(f"更新端口 {'成功' if success else '失败'}")
    elif args.info:
        info = generate_all_subscription_info()
        print(f"服务器IP: {info['server_ip']}")
        print(f"端口: {info['port']}")
        print(f"访问令牌: {info['token']}")
        print("\n订阅链接:")
        for client, link in info['links'].items():
            print(f"  {client.upper()}: {link}")
        print("\n配置的订阅源:")
        for i, sub in enumerate(info['subscriptions']):
            print(f"  {i}. {sub['name']} - {sub['url']}")
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
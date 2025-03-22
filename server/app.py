import os
import yaml
import uvicorn
from config.settings import load_config, check_config_file
from core.websocket_server import WebSocketServer
from core.utils.util import check_ffmpeg_installed, get_local_ip
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Request
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from config.logger import setup_logging

# 全局变量存储配置和处理模块
config = None
connection_handlers = {}
ws_server = None
logger = setup_logging()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动事件
    global config, ws_server
    check_config_file()
    check_ffmpeg_installed()
    config = load_config()
    
    # 创建WebSocketServer实例
    ws_server = WebSocketServer(config)
    
    # 记录服务器启动信息
    print(f"服务器已启动，WebSocket端点: ws://{get_local_ip()}:8000/ws")
    print(f"健康检查端点: http://{get_local_ip()}:8000/health")
    
    yield
    
    # 关闭事件
    await ws_server.close_all_connections()

app = FastAPI(title="AI Buddy WebSocket Server", lifespan=lifespan)

# 添加跨域支持
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境中应该限制来源
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    """健康检查端点，用于负载均衡器探测"""
    return {"status": "healthy", "service": "ai-buddy"}

@app.get("/")
async def root():
    """首页，提供简单的服务信息"""
    return {
        "service": "AI Buddy WebSocket服务器",
        "status": "运行中",
        "endpoints": {
            "websocket": "/ws",
            "health": "/health"
        }
    }

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket端点，处理所有WebSocket连接"""
    await websocket.accept()
    try:
        await ws_server._handle_connection(websocket)
    except WebSocketDisconnect:
        logger.info("WebSocket connection closed by client")
    except Exception as e:
        logger.error(f"WebSocket error: {str(e)}")
        try:
            await websocket.close()
        except RuntimeError:
            # 忽略'已关闭'的错误
            pass

if __name__ == "__main__":
    try:
        # 直接使用uvicorn启动FastAPI应用
        server_config = load_config()["server"]
        uvicorn.run(
            "app:app", 
            host=server_config.get("ip", "0.0.0.0"),
            port=server_config.get("port", 8000),
            reload=False
        )
    except KeyboardInterrupt:
        print("手动中断，程序终止。")

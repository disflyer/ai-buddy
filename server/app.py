import uvicorn
from config.settings import load_config, check_config_file
from core.websocket_server import WebSocketServer
from core.utils.util import check_ffmpeg_installed, get_local_ip
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Request
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="AI Buddy WebSocket Server")

# 添加跨域支持
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境中应该限制来源
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 全局变量存储配置和处理模块
config = None
connection_handlers = {}
ws_server = None

@app.on_event("startup")
async def startup_event():
    global config, ws_server
    check_config_file()
    check_ffmpeg_installed()
    config = load_config()
    
    # 创建WebSocketServer实例
    ws_server = WebSocketServer(config)
    
    # 记录服务器启动信息
    print(f"服务器已启动，WebSocket端点: ws://{get_local_ip()}:8000/ws")
    print(f"健康检查端点: http://{get_local_ip()}:8000/health")

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
    
    # 使用与原WebSocketServer相同的处理逻辑
    if ws_server:
        await ws_server._handle_connection(websocket)
    else:
        await websocket.close(code=1011, reason="服务器未初始化")

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

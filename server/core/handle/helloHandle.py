import json
from config.logger import setup_logging

TAG = __name__
logger = setup_logging()


async def handleHelloMessage(conn):
    """处理客户端hello消息"""
    if conn.welcome_msg is None:
        logger.bind(tag=TAG).warning("欢迎消息未初始化")
        # 创建默认欢迎消息
        welcome_msg = {
            "type": "hello",
            "version": conn.config["xiaozhi"].get("version", "1.0"),
            "transport": conn.config["xiaozhi"].get("transport", "websocket"),
            "audio_params": conn.config["xiaozhi"].get("audio_params", {
                "format": "opus",
                "sample_rate": 16000,
                "channels": 1
            }),
            "session_id": conn.session_id
        }
        await conn.websocket.send_text(json.dumps(welcome_msg))
    else:
        await conn.websocket.send_text(json.dumps(conn.welcome_msg))

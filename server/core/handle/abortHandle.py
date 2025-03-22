import json
import queue
from config.logger import setup_logging

TAG = __name__
logger = setup_logging()


async def handleAbortMessage(conn):
    logger.bind(tag=TAG).info("Abort message received")
    # 设置成打断状态，会自动打断llm、tts任务
    conn.client_abort = True
    logger.bind(tag="").debug(f"中断任务，清除队列中的tts")
    with conn.tts_queue.mutex:
        conn.tts_queue.queue.clear()
    conn.audio_play_queue.queue.clear()
    conn.clearSpeakStatus()
    await conn.websocket.send_text(json.dumps({"type": "tts", "state": "stop", "session_id": conn.session_id}))
    logger.bind(tag=TAG).info("Abort message received-end")

from config.logger import setup_logging
import json
import asyncio
import time
from core.utils.util import remove_punctuation_and_length, get_string_no_punctuation_or_emoji

TAG = __name__
logger = setup_logging()

async def sendAudioMessage(conn, opus_datas, text, text_index):
    """发送音频消息"""
    if not conn or conn.websocket is None:
        return

    # 第一次出声
    if text_index == conn.tts_first_text_index:
        conn.client_abort = False
        conn.asr_server_receive = False
        # 如果未设置欢迎语，则使用系统提示音
        # if conn.welcome_msg is not None:
        #     conn.welcome_msg = None
        conn.client_listen_mode = "auto"
        message = {
            "type": "tts",
            "state": "start",
            "sample_rate": 16000,
            "format": "opus",
            "channels": 1,
            "text": text.replace("\n", " "),
            "text_index": text_index,
            "session_id": conn.session_id
        }
        await conn.websocket.send_text(json.dumps(message))

    # 生成的TTS语音发送
    for opus_data in opus_datas:
        opus_packet = opus_data
        if opus_packet is None or len(opus_packet) <= 0:
            continue
        await conn.websocket.send_bytes(opus_packet)

    # 最后一条语音
    if text_index == conn.tts_last_text_index:
        await send_tts_end_message(conn, text)

async def send_tts_end_message(conn, text):
    """发送TTS结束消息"""
    conn.asr_server_receive = True
    conn.tts_first_text_index = -1
    conn.tts_last_text_index = -1
    end_message = {
        "type": "tts",
        "state": "end",
        "text": text.replace("\n", " "),
        "session_id": conn.session_id
    }
    await conn.websocket.send_text(json.dumps(end_message))
    
    # 如果需要在聊天后关闭连接，开始计时
    if conn.close_after_chat:
        conn.client_have_voice_last_time = time.time() * 1000
        # 执行关闭动作
        await conn.close()

async def send_stt_message(conn, text):
    """发送STT识别结果"""
    message = {
        "type": "stt",
        "text": text.replace("\n", " "),
        "session_id": conn.session_id
    }
    await conn.websocket.send_text(json.dumps(message))

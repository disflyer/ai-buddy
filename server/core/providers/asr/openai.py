import os
import wave
import uuid
from typing import Optional, Tuple, List
import logging
import openai
import opuslib_next
from .base import ASRProviderBase
from config.logger import setup_logging

TAG = __name__
logger = setup_logging()

class ASRProvider(ASRProviderBase):
    """OpenAI ASR Provider using Whisper API"""

    def __init__(self, config: dict, delete_audio_file: bool):
        """初始化 OpenAI ASR Provider

        Args:
            config (dict): 配置字典
            delete_audio_file (bool): 是否删除音频文件
        """
        # 从配置中获取必要参数
        self.api_key = config.get("api_key")
        if not self.api_key:
            raise ValueError("OpenAI API key not found in config")

        self.api_base = config.get("api_base")
        if self.api_base:
            openai.base_url = self.api_base

        self.output_dir = config.get("output_dir", "tmp/")
        self.delete_audio_file = delete_audio_file

        # 确保输出目录存在
        os.makedirs(self.output_dir, exist_ok=True)

        # 配置 OpenAI client
        self.client = openai.OpenAI(api_key=self.api_key)

    def save_audio_to_file(self, opus_data: List[bytes], session_id: str) -> str:
        """将Opus音频数据解码并保存为WAV文件

        Args:
            opus_data (List[bytes]): Opus编码的音频数据列表
            session_id (str): 会话ID

        Returns:
            str: 保存的文件路径
        """
        file_name = f"asr_{session_id}_{uuid.uuid4()}.wav"
        file_path = os.path.join(self.output_dir, file_name)

        decoder = opuslib_next.Decoder(16000, 1)  # 16kHz, 单声道
        pcm_data = []

        for opus_packet in opus_data:
            try:
                pcm_frame = decoder.decode(opus_packet, 960)  # 960 samples = 60ms
                pcm_data.append(pcm_frame)
            except opuslib_next.OpusError as e:
                logger.bind(tag=TAG).error(f"Opus解码错误: {e}", exc_info=True)

        with wave.open(file_path, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)  # 2 bytes = 16-bit
            wf.setframerate(16000)
            wf.writeframes(b"".join(pcm_data))

        return file_path

    async def speech_to_text(self, opus_data: List[bytes], session_id: str) -> Tuple[Optional[str], Optional[str]]:
        """将语音数据转换为文本

        Args:
            opus_data (List[bytes]): Opus编码的音频数据列表
            session_id (str): 会话ID

        Returns:
            Tuple[Optional[str], Optional[str]]: (转录文本, 错误信息)
        """
        try:
            # 保存音频文件
            wav_file = self.save_audio_to_file(opus_data, session_id)
            
            # 发送识别请求
            with open(wav_file, "rb") as audio_file:
                response = self.client.audio.transcriptions.create(
                    model="whisper-1",
                    file=audio_file,
                    response_format="text"
                )

            # 删除临时文件
            if self.delete_audio_file and os.path.exists(wav_file):
                os.remove(wav_file)

            # 处理识别结果
            if response:
                text = response.strip()
                logger.bind(tag=TAG).info(f"OpenAI Whisper 转录成功: {text}")
                return text, None
            else:
                logger.bind(tag=TAG).warning("OpenAI Whisper 未返回文本")
                return "", None

        except Exception as e:
            logger.bind(tag=TAG).error(f"OpenAI Whisper 转录失败: {str(e)}", exc_info=True)
            return "", str(e)

    @property
    def name(self) -> str:
        """获取提供者名称

        Returns:
            str: 提供者名称
        """
        return "openai" 
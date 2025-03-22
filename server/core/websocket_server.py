import asyncio
from config.logger import setup_logging
from core.connection import ConnectionHandler
from core.handle.musicHandler import MusicHandler
from core.utils.util import get_local_ip
from core.utils import asr, vad, llm, tts, memory, intent

TAG = __name__


class WebSocketServer:
    def __init__(self, config: dict):
        self.config = config
        self.logger = setup_logging()
        self._vad, self._asr, self._llm, self._tts, self._music, self._memory, self.intent = self._create_processing_instances()
        self.active_connections = set()  # 添加全局连接记录

    def _create_processing_instances(self):
        memory_cls_name = self.config["selected_module"].get("Memory", "nomem") # 默认使用nomem
        has_memory_cfg = self.config.get("Memory") and memory_cls_name in self.config["Memory"]
        memory_cfg = self.config["Memory"][memory_cls_name] if has_memory_cfg else {}

        # 创建各模块实例
        # VAD模块
        vad_module = vad.create_instance(
            self.config["selected_module"]["VAD"],
            self.config["VAD"][self.config["selected_module"]["VAD"]]
        )
        
        # ASR模块
        asr_type = self.config["selected_module"]["ASR"]
        if 'type' in self.config["ASR"][asr_type]:
            asr_type = self.config["ASR"][asr_type]["type"]
        asr_module = asr.create_instance(
            asr_type,
            self.config["ASR"][self.config["selected_module"]["ASR"]],
            self.config["delete_audio"]
        )
        
        # LLM模块
        llm_type = self.config["selected_module"]["LLM"]
        if 'type' in self.config["LLM"][llm_type]:
            llm_type = self.config["LLM"][llm_type]['type']
        llm_module = llm.create_instance(
            llm_type,
            self.config["LLM"][self.config["selected_module"]["LLM"]]
        )
        
        # TTS模块
        tts_type = self.config["selected_module"]["TTS"]
        if 'type' in self.config["TTS"][tts_type]:
            tts_type = self.config["TTS"][tts_type]["type"]
        tts_module = tts.create_instance(
            tts_type,
            self.config["TTS"][self.config["selected_module"]["TTS"]],
            self.config["delete_audio"]
        )
        
        # Music模块
        music_module = MusicHandler(self.config)
        
        # Memory模块
        memory_module = memory.create_instance(memory_cls_name, memory_cfg)
        
        # Intent模块
        intent_type = self.config["selected_module"]["Intent"]
        if 'type' in self.config["Intent"][intent_type]:
            intent_type = self.config["Intent"][intent_type]["type"]
        intent_module = intent.create_instance(
            intent_type,
            self.config["Intent"][self.config["selected_module"]["Intent"]]
        )
        
        return (
            vad_module,
            asr_module,
            llm_module,
            tts_module,
            music_module,
            memory_module,
            intent_module
        )

    async def _handle_connection(self, websocket):
        """处理新连接，每次创建独立的ConnectionHandler"""
        handler = ConnectionHandler(self.config, self._vad, self._asr, self._llm, self._tts, self._music, self._memory, self.intent)
        self.active_connections.add(handler)
        try:
            await handler.handle_connection(websocket)
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"连接处理异常: {str(e)}")
        finally:
            # 确保从活动连接集合中移除
            self.active_connections.discard(handler)
            
    async def close_all_connections(self):
        """关闭所有活动连接"""
        close_tasks = []
        for handler in list(self.active_connections):
            close_tasks.append(handler.close())
        if close_tasks:
            await asyncio.gather(*close_tasks, return_exceptions=True)
        self.active_connections.clear()

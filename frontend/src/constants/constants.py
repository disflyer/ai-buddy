class ListeningMode:
    """监听模式"""
    ALWAYS_ON = "always_on"
    AUTO_STOP = "auto_stop"
    MANUAL = "manual"

class AbortReason:
    """中止原因"""
    NONE = "none"
    WAKE_WORD_DETECTED = "wake_word_detected"

class DeviceState:
    """设备状态"""
    IDLE = "idle"
    CONNECTING = "connecting"
    LISTENING = "listening"
    SPEAKING = "speaking"

class EventType:
    """事件类型"""
    SCHEDULE_EVENT = "schedule_event"
    AUDIO_INPUT_READY_EVENT = "audio_input_ready_event"
    AUDIO_OUTPUT_READY_EVENT = "audio_output_ready_event"

class AudioConfig:
    """音频配置"""
    SAMPLE_RATE = 48000  # 使用设备的原生采样率
    CHANNELS = 1         # 保持单声道
    FRAME_DURATION = 20  # 20ms 的帧时长
    FRAME_SIZE = int(SAMPLE_RATE * FRAME_DURATION / 1000)  # 根据采样率计算帧大小
    FORMAT = "opus"
    SILENCE_THRESHOLD = 50
    DEBUG_AUDIO = True
    DEBUG_AUDIO_LEVEL = True

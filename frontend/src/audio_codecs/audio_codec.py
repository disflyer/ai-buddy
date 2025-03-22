import logging
import queue
import numpy as np
import pyaudio
import opuslib
from src.constants.constants import AudioConfig
import time
import sys

logger = logging.getLogger("AudioCodec")


class AudioCodec:
    """音频编解码器类，处理音频的录制和播放"""

    def __init__(self):
        """初始化音频编解码器"""
        self.audio = None
        self.input_stream = None
        self.output_stream = None
        self.opus_encoder = None
        self.opus_decoder = None
        self.audio_decode_queue = queue.Queue()
        self._is_closing = False  # 添加关闭状态标志
        self._retry_count = 0
        self._max_retries = 3

        self._initialize_audio()

    def _initialize_audio(self):
        """初始化音频设备和编解码器"""
        try:
            self.audio = pyaudio.PyAudio()
            
            # 获取并打印系统音频信息
            info = self.audio.get_host_api_info_by_index(0)
            logger.info(f"音频系统信息: {info['name']}")
            
            device_count = self.audio.get_device_count()
            logger.info(f"发现 {device_count} 个音频设备")
            
            # 打印所有可用的音频设备信息
            for i in range(device_count):
                device_info = self.audio.get_device_info_by_index(i)
                logger.info(f"设备 {i}: {device_info['name']}")
                logger.info(f"  最大输入通道: {device_info['maxInputChannels']}")
                logger.info(f"  最大输出通道: {device_info['maxOutputChannels']}")
                logger.info(f"  默认采样率: {device_info['defaultSampleRate']}")

            # 获取默认设备索引
            input_device_index = self._get_default_input_device()
            output_device_index = self._get_default_output_device()

            # 获取设备的详细信息
            if input_device_index is not None:
                input_device_info = self.audio.get_device_info_by_index(input_device_index)
                logger.info(f"输入设备详细信息: {input_device_info}")
            
            if output_device_index is not None:
                output_device_info = self.audio.get_device_info_by_index(output_device_index)
                logger.info(f"输出设备详细信息: {output_device_info}")

            # 初始化音频输入流
            logger.info("正在初始化输入流...")
            logger.info(f"采样率: {AudioConfig.SAMPLE_RATE}")
            logger.info(f"通道数: {AudioConfig.CHANNELS}")
            logger.info(f"帧大小: {AudioConfig.FRAME_SIZE}")
            
            self.input_stream = self.audio.open(
                format=pyaudio.paInt16,
                channels=AudioConfig.CHANNELS,
                rate=AudioConfig.SAMPLE_RATE,
                input=True,
                frames_per_buffer=AudioConfig.FRAME_SIZE,
                input_device_index=input_device_index,
                stream_callback=None
            )

            # 初始化音频输出流
            logger.info("正在初始化输出流...")
            self.output_stream = self.audio.open(
                format=pyaudio.paInt16,
                channels=AudioConfig.CHANNELS,
                rate=AudioConfig.SAMPLE_RATE,
                output=True,
                frames_per_buffer=AudioConfig.FRAME_SIZE,
                output_device_index=output_device_index,
                stream_callback=None
            )

            # 初始化Opus编码器
            logger.info("正在初始化Opus编码器...")
            try:
                self.opus_encoder = opuslib.Encoder(
                    fs=AudioConfig.SAMPLE_RATE,
                    channels=AudioConfig.CHANNELS,
                    application=opuslib.APPLICATION_VOIP
                )
                logger.info("Opus编码器初始化成功")
            except Exception as e:
                logger.error(f"Opus编码器初始化失败: {str(e)}")
                logger.error(f"错误类型: {type(e).__name__}")
                logger.exception("详细错误信息：")
                raise

            # 初始化Opus解码器
            logger.info("正在初始化Opus解码器...")
            try:
                self.opus_decoder = opuslib.Decoder(
                    fs=AudioConfig.SAMPLE_RATE,
                    channels=AudioConfig.CHANNELS
                )
                logger.info("Opus解码器初始化成功")
            except Exception as e:
                logger.error(f"Opus解码器初始化失败: {str(e)}")
                logger.error(f"错误类型: {type(e).__name__}")
                logger.exception("详细错误信息：")
                raise

            logger.info("音频设备和编解码器初始化成功")
            self._retry_count = 0
        except Exception as e:
            logger.error(f"初始化音频设备失败: {str(e)}")
            logger.error(f"错误类型: {type(e).__name__}")
            logger.exception("详细错误信息：")
            
            if self._retry_count < self._max_retries:
                self._retry_count += 1
                logger.info(f"尝试重新初始化 (第 {self._retry_count} 次)")
                time.sleep(1)
                self._initialize_audio()
            else:
                raise

    def _get_default_input_device(self):
        """获取默认输入设备的索引"""
        try:
            default_device = self.audio.get_default_input_device_info()
            logger.info(f"使用默认输入设备: {default_device['name']}")
            return default_device['index']
        except Exception as e:
            logger.warning(f"获取默认输入设备失败: {e}，使用默认索引None")
            return None

    def _get_default_output_device(self):
        """获取默认输出设备的索引"""
        try:
            default_device = self.audio.get_default_output_device_info()
            logger.info(f"使用默认输出设备: {default_device['name']}")
            return default_device['index']
        except Exception as e:
            logger.warning(f"获取默认输出设备失败: {e}，使用默认索引None")
            return None

    def read_audio(self):
        """读取音频输入数据并编码"""
        try:
            if not self.input_stream:
                logger.error("输入流未初始化")
                return None

            if not self.input_stream.is_active():
                logger.warning("输入流未激活，尝试重新启动")
                try:
                    self.input_stream.start_stream()
                    logger.info("输入流重新启动成功")
                except Exception as e:
                    logger.error(f"启动输入流失败: {e}")
                    if "Stream closed" in str(e):
                        logger.info("检测到流已关闭，尝试重新初始化")
                        self._reinitialize_input_stream()
                    return None

            # 读取音频数据
            try:
                if AudioConfig.DEBUG_AUDIO:
                    logger.debug("开始读取音频数据...")
                data = self.input_stream.read(AudioConfig.FRAME_SIZE, exception_on_overflow=False)
                if AudioConfig.DEBUG_AUDIO:
                    logger.debug(f"读取到原始音频数据大小: {len(data) if data else 0} 字节")
            except OSError as e:
                if "Input overflowed" in str(e):
                    logger.warning("输入缓冲区溢出，跳过此帧")
                    return None
                logger.error(f"读取音频数据时出错: {e}")
                if "Stream closed" in str(e):
                    self._reinitialize_input_stream()
                return None
            except Exception as e:
                logger.error(f"读取音频数据时发生未知错误: {e}")
                logger.exception("详细错误信息：")
                return None

            if not data:
                if AudioConfig.DEBUG_AUDIO:
                    logger.debug("没有读取到音频数据")
                return None

            # 将字节数据转换为numpy数组
            try:
                audio_data = np.frombuffer(data, dtype=np.int16)
                
                # 检查音频数据是否全为静音
                max_amplitude = np.abs(audio_data).max()
                rms = np.sqrt(np.mean(np.square(audio_data)))
                
                if AudioConfig.DEBUG_AUDIO_LEVEL:
                    logger.debug(f"音频电平 - 最大振幅: {max_amplitude}, RMS: {rms:.2f}")
                
                if max_amplitude < AudioConfig.SILENCE_THRESHOLD:
                    if AudioConfig.DEBUG_AUDIO:
                        logger.debug(f"检测到静音 (最大振幅 {max_amplitude} < 阈值 {AudioConfig.SILENCE_THRESHOLD})")
                    return None

                # 验证音频数据的有效性
                if len(audio_data) != AudioConfig.FRAME_SIZE:
                    logger.warning(f"音频帧大小不匹配: 期望 {AudioConfig.FRAME_SIZE}, 实际 {len(audio_data)}")
                    return None

                # 确保数据类型正确
                if audio_data.dtype != np.int16:
                    logger.warning(f"音频数据类型不正确: {audio_data.dtype}")
                    audio_data = audio_data.astype(np.int16)

                # 编码音频数据
                try:
                    encoded_data = self.opus_encoder.encode(audio_data.tobytes(), AudioConfig.FRAME_SIZE)
                    if AudioConfig.DEBUG_AUDIO:
                        logger.debug(f"音频数据编码成功，原始大小: {len(data)}，编码后大小: {len(encoded_data)}")
                    return encoded_data
                except Exception as e:
                    logger.error(f"音频编码失败: {e}")
                    logger.exception("详细错误信息：")
                    # 尝试重新初始化编码器
                    self._reinitialize_encoder()
                    return None
                
            except Exception as e:
                logger.error(f"处理音频数据时出错: {e}")
                logger.exception("详细错误信息：")
                return None
            
        except Exception as e:
            logger.error(f"读取音频输入时出错: {e}")
            logger.exception("详细错误信息：")
            return None

    def write_audio(self, opus_data):
        """将编码的音频数据添加到播放队列"""
        try:
            if opus_data:
                if AudioConfig.DEBUG_AUDIO:
                    logger.debug(f"添加音频数据到播放队列，大小: {len(opus_data)} 字节")
                self.audio_decode_queue.put(opus_data)
            else:
                logger.warning("收到空的音频数据")
        except Exception as e:
            logger.error(f"添加音频数据到队列时出错: {e}")
            logger.exception("详细错误信息：")

    def play_audio(self):
        """处理并播放队列中的音频数据"""
        try:
            # 增加批处理大小以减少中断
            batch_size = min(30, self.audio_decode_queue.qsize())  # 增加到30个包
            if batch_size == 0:
                return False

            logger.info(f"开始处理音频数据，队列中有 {self.audio_decode_queue.qsize()} 个数据包")
            # 创建缓冲区存储解码后的数据
            buffer = bytearray()
            decode_buffer_size = AudioConfig.FRAME_SIZE * 4  # 直接使用更大的缓冲区

            for i in range(batch_size):
                if self.audio_decode_queue.empty():
                    break

                opus_data = self.audio_decode_queue.get_nowait()
                try:
                    if AudioConfig.DEBUG_AUDIO:
                        logger.debug(f"正在解码第 {i+1}/{batch_size} 个音频包，大小: {len(opus_data)} 字节")
                    
                    pcm_data = self.opus_decoder.decode(opus_data, decode_buffer_size)
                    
                    if pcm_data:
                        buffer.extend(pcm_data)
                        if AudioConfig.DEBUG_AUDIO:
                            logger.debug(f"解码成功，PCM数据大小: {len(pcm_data)} 字节")
                    else:
                        logger.warning("解码结果为空")
                except Exception as e:
                    logger.error(f"解码音频数据时出错: {e}")
                    continue

            # 只有在有数据时才处理和播放
            buffer_size = len(buffer)
            if buffer_size > 0:
                logger.info(f"准备播放音频，缓冲区大小: {buffer_size} 字节")
                # 转换为numpy数组
                try:
                    pcm_array = np.frombuffer(buffer, dtype=np.int16)
                    if AudioConfig.DEBUG_AUDIO:
                        logger.debug(f"PCM数组大小: {len(pcm_array)}, 最大值: {np.max(np.abs(pcm_array))}")

                    # 检查音频数据是否有效
                    if np.max(np.abs(pcm_array)) == 0:
                        logger.warning("检测到静音数据")
                        return False

                    # 播放音频
                    if not self.output_stream:
                        logger.error("输出流未初始化")
                        self._reinitialize_output_stream()
                        return False

                    if not self.output_stream.is_active():
                        logger.warning("输出流未激活，尝试重新启动")
                        try:
                            self.output_stream.start_stream()
                        except Exception as e:
                            logger.error(f"启动输出流失败: {e}")
                            self._reinitialize_output_stream()
                            return False

                    try:
                        # 确保数据大小是帧大小的整数倍
                        frames_count = len(pcm_array) // AudioConfig.FRAME_SIZE
                        if frames_count > 0:
                            valid_size = frames_count * AudioConfig.FRAME_SIZE
                            pcm_array = pcm_array[:valid_size]
                            
                            # 使用较小的块大小进行播放，避免长时间阻塞
                            chunk_size = AudioConfig.FRAME_SIZE * 10
                            for i in range(0, len(pcm_array), chunk_size):
                                chunk = pcm_array[i:i + chunk_size]
                                self.output_stream.write(chunk.tobytes())
                                
                            logger.info("音频播放成功")
                            return True
                        else:
                            logger.warning("音频数据太短，无法播放")
                            return False
                    except OSError as e:
                        if "Stream closed" in str(e) or "Internal PortAudio error" in str(e):
                            logger.error(f"播放音频时出错: {e}")
                            self._reinitialize_output_stream()
                        else:
                            logger.error(f"播放音频时出错: {e}")
                        return False
                    except Exception as e:
                        logger.error(f"播放音频时出错: {e}")
                        logger.exception("详细错误信息：")
                        return False
                except Exception as e:
                    logger.error(f"处理PCM数据时出错: {e}")
                    logger.exception("详细错误信息：")
                    return False
            else:
                if AudioConfig.DEBUG_AUDIO:
                    logger.debug("没有可播放的音频数据")
                return False

        except queue.Empty:
            if AudioConfig.DEBUG_AUDIO:
                logger.debug("音频队列为空")
            return False
        except Exception as e:
            logger.error(f"播放音频时出错: {e}")
            logger.exception("详细错误信息：")
            self._reinitialize_output_stream()
            return False

    def has_pending_audio(self):
        """检查是否还有待播放的音频数据"""
        return not self.audio_decode_queue.empty()

    def wait_for_audio_complete(self, timeout=5.0):
        # 等待音频队列清空
        attempt = 0
        max_attempts = 15
        while not self.audio_decode_queue.empty() and attempt < max_attempts:
            time.sleep(0.1)
            attempt += 1

        # 在关闭前清空任何剩余数据
        while not self.audio_decode_queue.empty():
            try:
                self.audio_decode_queue.get_nowait()
            except queue.Empty:
                break

    def clear_audio_queue(self):
        """清空音频队列"""
        while not self.audio_decode_queue.empty():
            try:
                self.audio_decode_queue.get_nowait()
            except queue.Empty:
                break

    def start_streams(self):
        """启动音频流"""
        if not self.input_stream.is_active():
            self.input_stream.start_stream()
        if not self.output_stream.is_active():
            self.output_stream.start_stream()

    def stop_streams(self):
        """停止音频流"""
        if self.input_stream and self.input_stream.is_active():
            self.input_stream.stop_stream()
        if self.output_stream and self.output_stream.is_active():
            self.output_stream.stop_stream()

    def _reinitialize_output_stream(self):
        """重新初始化音频输出流"""
        if self._is_closing:  # 如果正在关闭，不要重新初始化
            return
        
        try:
            if self.output_stream:
                self.output_stream.close()
            
            self.output_stream = self.audio.open(
                format=pyaudio.paInt16,
                channels=AudioConfig.CHANNELS,
                rate=AudioConfig.SAMPLE_RATE,
                output=True,
                frames_per_buffer=AudioConfig.FRAME_SIZE,
                output_device_index=self._get_default_output_device()
            )
            logger.info("音频输出流重新初始化成功")
        except Exception as e:
            logger.error(f"重新初始化音频输出流失败: {e}")

    def close(self):
        """关闭音频设备和编解码器"""
        self._is_closing = True
        
        # 等待音频队列清空
        self.wait_for_audio_complete()
        
        # 关闭流
        if self.input_stream:
            self.input_stream.stop_stream()
            self.input_stream.close()
        if self.output_stream:
            self.output_stream.stop_stream()
            self.output_stream.close()
            
        # 关闭PyAudio
        if self.audio:
            self.audio.terminate()
            
        # 清理编解码器
        if self.opus_encoder:
            del self.opus_encoder
        if self.opus_decoder:
            del self.opus_decoder
            
        logger.info("音频设备和编解码器已关闭")

    def __del__(self):
        """析构函数，确保资源被释放"""
        self.close()

    def _reinitialize_encoder(self):
        """重新初始化Opus编码器"""
        try:
            if self.opus_encoder:
                del self.opus_encoder
            
            self.opus_encoder = opuslib.Encoder(
                fs=AudioConfig.SAMPLE_RATE,
                channels=AudioConfig.CHANNELS,
                application=opuslib.APPLICATION_VOIP
            )
            logger.info("Opus编码器重新初始化成功")
        except Exception as e:
            logger.error(f"重新初始化Opus编码器失败: {e}")
            logger.exception("详细错误信息：")

    def _reinitialize_input_stream(self):
        """重新初始化音频输入流"""
        try:
            if self.input_stream:
                self.input_stream.close()
            
            self.input_stream = self.audio.open(
                format=pyaudio.paInt16,
                channels=AudioConfig.CHANNELS,
                rate=AudioConfig.SAMPLE_RATE,
                input=True,
                frames_per_buffer=AudioConfig.FRAME_SIZE,
                input_device_index=self._get_default_input_device()
            )
            logger.info("音频输入流重新初始化成功")
        except Exception as e:
            logger.error(f"重新初始化音频输入流失败: {e}")

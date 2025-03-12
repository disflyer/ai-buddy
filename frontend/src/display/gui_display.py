import threading
import tkinter as tk
from tkinter import ttk
import queue
import logging
import time
from typing import Optional, Callable
from pynput import keyboard as pynput_keyboard

from src.display.base_display import BaseDisplay


class GuiDisplay(BaseDisplay):
    def __init__(self):
        super().__init__()  # 调用父类初始化
        """创建 GUI 界面"""
        # 初始化日志
        self.logger = logging.getLogger("Display")

        # 创建主窗口
        self.root = tk.Tk()
        self.root.title("小小花Ai语音控制")
        self.root.geometry("300x350")  # 增加高度以容纳快捷键提示

        # 状态显示
        self.status_frame = ttk.Frame(self.root)
        self.status_frame.pack(pady=10)
        self.status_label = ttk.Label(self.status_frame, text="状态: 未连接")
        self.status_label.pack(side=tk.LEFT)

        # 表情显示
        self.emotion_label = tk.Label(self.root, text="😊", font=("Segoe UI Emoji", 16))
        self.emotion_label.pack(padx=20, pady=20)

        # TTS文本显示
        self.tts_text_label = ttk.Label(self.root, text="待命", wraplength=250)
        self.tts_text_label.pack(padx=20, pady=10)

        # 音量控制
        self.volume_frame = ttk.Frame(self.root)
        self.volume_frame.pack(pady=10)
        ttk.Label(self.volume_frame, text="音量:").pack(side=tk.LEFT)
        
        # 添加音量更新节流
        self.volume_update_timer = None
        self.volume_scale = ttk.Scale(
            self.volume_frame,
            from_=0,
            to=100,
            command=self._on_volume_change
        )
        self.volume_scale.set(self.current_volume)
        self.volume_scale.pack(side=tk.LEFT, padx=10)

        # 控制按钮
        self.btn_frame = ttk.Frame(self.root)
        self.btn_frame.pack(pady=20)
        
        # 手动模式按钮 - 默认不显示
        self.manual_btn = ttk.Button(self.btn_frame, text="按住说话")
        self.manual_btn.bind("<ButtonPress-1>", self._on_manual_button_press)
        self.manual_btn.bind("<ButtonRelease-1>", self._on_manual_button_release)
        # 不立即pack，因为默认是自动模式
        
        # 打断按钮 - 放在中间
        self.abort_btn = ttk.Button(self.btn_frame, text="打断", command=self._on_abort_button_click)
        self.abort_btn.pack(side=tk.LEFT, padx=10)
        
        # 自动模式按钮 - 默认显示
        self.auto_btn = ttk.Button(self.btn_frame, text="开始对话", command=self._on_auto_button_click)
        self.auto_btn.pack(side=tk.LEFT, padx=10, before=self.abort_btn)  # 默认显示自动按钮
        
        # 模式切换按钮
        self.mode_btn = ttk.Button(self.btn_frame, text="自动对话", command=self._on_mode_button_click)
        self.mode_btn.pack(side=tk.LEFT, padx=10)
        
        # 添加快捷键提示
        self.shortcut_frame = ttk.Frame(self.root)
        self.shortcut_frame.pack(pady=5)
        self.shortcut_label = ttk.Label(
            self.shortcut_frame, 
            text="快捷键: F3=打断 | F4=开始对话",
            font=("Arial", 8)
        )
        self.shortcut_label.pack()
        
        # 对话模式标志 - 默认为自动模式
        self.auto_mode = True

        # 回调函数
        self.button_press_callback = None
        self.button_release_callback = None
        self.status_update_callback = None
        self.text_update_callback = None
        self.emotion_update_callback = None
        self.mode_callback = None
        self.auto_callback = None
        self.abort_callback = None

        # 更新队列
        self.update_queue = queue.Queue()

        # 运行标志
        self._running = True

        # 设置窗口关闭处理
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

        # 启动更新处理
        self.root.after(100, self._process_updates)

        self.keyboard_listener = None
        
        # 确保界面初始状态为自动模式
        self.update_mode_button_status("自动对话")

        # 键盘监听状态
        self.keyboard_listener_active = False

    def set_callbacks(self,
                      press_callback: Optional[Callable] = None,
                      release_callback: Optional[Callable] = None,
                      status_callback: Optional[Callable] = None,
                      text_callback: Optional[Callable] = None,
                      emotion_callback: Optional[Callable] = None,
                      mode_callback: Optional[Callable] = None,
                      auto_callback: Optional[Callable] = None,
                      abort_callback: Optional[Callable] = None):
        """设置回调函数"""
        self.button_press_callback = press_callback
        self.button_release_callback = release_callback
        self.status_update_callback = status_callback
        self.text_update_callback = text_callback
        self.emotion_update_callback = emotion_callback
        self.mode_callback = mode_callback
        self.auto_callback = auto_callback
        self.abort_callback = abort_callback


    def _process_updates(self):
        """处理更新队列"""
        try:
            while True:
                try:
                    # 非阻塞方式获取更新
                    update_func = self.update_queue.get_nowait()
                    update_func()
                    self.update_queue.task_done()
                except queue.Empty:
                    break
        finally:
            if self._running:
                self.root.after(100, self._process_updates)

    def _on_manual_button_press(self, event):
        """手动模式按钮按下事件处理"""
        try:
            # 更新按钮文本为"松开以停止"
            self.manual_btn.config(text="松开以停止")
            
            # 调用回调函数
            if self.button_press_callback:
                self.button_press_callback()
        except Exception as e:
            self.logger.error(f"按钮按下回调执行失败: {e}")

    def _on_manual_button_release(self, event):
        """手动模式按钮释放事件处理"""
        try:
            # 更新按钮文本为"按住说话"
            self.manual_btn.config(text="按住说话")
            
            # 调用回调函数
            if self.button_release_callback:
                self.button_release_callback()
        except Exception as e:
            self.logger.error(f"按钮释放回调执行失败: {e}")
            
    def _on_auto_button_click(self):
        """自动模式按钮点击事件处理"""
        try:
            # 更新按钮状态，提供视觉反馈
            self.auto_btn.config(text="对话中...", state="disabled")
            
            # 调用回调函数
            if self.auto_callback:
                self.auto_callback()
        except Exception as e:
            # 发生错误时恢复按钮状态
            self.auto_btn.config(text="开始对话", state="normal")
            self.logger.error(f"自动模式按钮回调执行失败: {e}")

    def _on_abort_button_click(self):
        """打断按钮点击事件处理"""
        try:
            # 更新按钮状态，提供视觉反馈
            self.abort_btn.config(text="打断中...", state="disabled")
            
            # 短暂延迟后恢复按钮状态
            self.root.after(1000, lambda: self.abort_btn.config(text="打断", state="normal"))
            
            # 调用回调函数
            if self.abort_callback:
                self.abort_callback()
        except Exception as e:
            # 发生错误时恢复按钮状态
            self.abort_btn.config(text="打断", state="normal")
            self.logger.error(f"打断按钮回调执行失败: {e}")

    def _on_mode_button_click(self):
        """对话模式切换按钮点击事件"""
        try:
            # 检查是否可以切换模式（通过回调函数询问应用程序当前状态）
            if self.mode_callback:
                # 如果回调函数返回False，表示当前不能切换模式
                if not self.mode_callback(not self.auto_mode):
                    return
                    
            # 切换模式
            self.auto_mode = not self.auto_mode
            
            # 更新按钮显示
            if self.auto_mode:
                # 切换到自动模式
                self.update_mode_button_status("自动对话")
                
                # 隐藏手动按钮，显示自动按钮
                self.update_queue.put(lambda: self._switch_to_auto_mode())
            else:
                # 切换到手动模式
                self.update_mode_button_status("手动对话")
                
                # 隐藏自动按钮，显示手动按钮
                self.update_queue.put(lambda: self._switch_to_manual_mode())
                
        except Exception as e:
            self.logger.error(f"模式切换按钮回调执行失败: {e}")
            
    def _switch_to_auto_mode(self):
        """切换到自动模式的UI更新"""
        self.manual_btn.pack_forget()  # 移除手动按钮
        self.auto_btn.pack(side=tk.LEFT, padx=10, before=self.abort_btn)  # 显示自动按钮，放在打断按钮前面
        
    def _switch_to_manual_mode(self):
        """切换到手动模式的UI更新"""
        self.auto_btn.pack_forget()  # 移除自动按钮
        self.manual_btn.pack(side=tk.LEFT, padx=10, before=self.abort_btn)  # 显示手动按钮，放在打断按钮前面

    def update_status(self, status: str):
        """更新状态文本"""
        self.update_queue.put(lambda: self.status_label.config(text=f"状态: {status}"))

    def update_text(self, text: str):
        """更新TTS文本"""
        self.update_queue.put(lambda: self.tts_text_label.config(text=text))

    def update_emotion(self, emotion: str):
        """更新表情"""
        self.update_queue.put(lambda: self.emotion_label.config(text=emotion))

    def start_update_threads(self):
        """启动更新线程"""

        def update_loop():
            while self._running:
                try:
                    # 更新状态
                    if self.status_update_callback:
                        status = self.status_update_callback()
                        if status:
                            self.update_status(status)

                    # 更新文本
                    if self.text_update_callback:
                        text = self.text_update_callback()
                        if text:
                            self.update_text(text)

                    # 更新表情
                    if self.emotion_update_callback:
                        emotion = self.emotion_update_callback()
                        if emotion:
                            self.update_emotion(emotion)

                except Exception as e:
                    self.logger.error(f"更新失败: {e}")
                time.sleep(0.1)

        threading.Thread(target=update_loop, daemon=True).start()

    def on_close(self):
        """关闭窗口处理"""
        self._running = False
        self.root.destroy()
        self.stop_keyboard_listener()

    def start(self):
        """启动GUI"""
        # 启动键盘监听
        self.start_keyboard_listener()
        
        # 如果外部键盘监听失败，设置 tkinter 键盘绑定作为备用
        if not self.keyboard_listener_active:
            self._setup_tkinter_key_bindings()
            
        # 启动更新线程
        self.start_update_threads()
        # 在主线程中运行主循环
        self.root.mainloop()

    def update_mode_button_status(self, text: str):
        """更新模式按钮状态"""
        self.update_queue.put(lambda: self.mode_btn.config(text=text))

    def update_button_status(self, text: str):
        """更新按钮状态 - 保留此方法以满足抽象基类要求"""
        # 根据当前模式更新相应的按钮
        if self.auto_mode:
            self.update_queue.put(lambda: self.auto_btn.config(text=text))
        else:
            # 在手动模式下，不通过此方法更新按钮文本
            # 因为按钮文本由按下/释放事件直接控制
            pass

    def _on_volume_change(self, value):
        """处理音量滑块变化，使用节流"""
        # 取消之前的定时器
        if self.volume_update_timer is not None:
            self.root.after_cancel(self.volume_update_timer)
        
        # 设置新的定时器，300ms 后更新音量
        self.volume_update_timer = self.root.after(
            300, 
            lambda: self.update_volume(int(float(value)))
        )

    def start_keyboard_listener(self):
        """启动键盘监听"""
        try:
            def on_press(key):
                try:
                    # F2 按键处理 - 按住说话（仅在手动模式下）
                    if key == pynput_keyboard.Key.f2 and not self.auto_mode:
                        if self.button_press_callback:
                            self.button_press_callback()
                            self.update_button_status("松开以停止")
                    # F3 按键处理 - 打断（在任何模式下都可用）
                    elif key == pynput_keyboard.Key.f3:
                        # 更新按钮状态，提供视觉反馈
                        self.update_queue.put(lambda: self.abort_btn.config(text="打断中...", state="disabled"))
                        
                        # 短暂延迟后恢复按钮状态
                        self.update_queue.put(lambda: self.root.after(
                            1000, 
                            lambda: self.abort_btn.config(text="打断", state="normal")
                        ))
                        
                        if self.abort_callback:
                            self.abort_callback()
                    # F4 按键处理 - 自动对话（仅在自动模式下）
                    elif key == pynput_keyboard.Key.f4 and self.auto_mode:
                        # 更新按钮状态，提供视觉反馈
                        self.update_queue.put(lambda: self.auto_btn.config(text="对话中...", state="disabled"))
                        
                        # 短暂延迟后恢复按钮状态
                        self.update_queue.put(lambda: self.root.after(
                            2000, 
                            lambda: self.auto_btn.config(text="开始对话", state="normal")
                        ))
                        
                        if self.auto_callback:
                            self.auto_callback()
                except Exception as e:
                    # 发生错误时恢复按钮状态
                    self.update_queue.put(lambda: self.auto_btn.config(text="开始对话", state="normal"))
                    self.logger.error(f"键盘事件处理错误: {e}")

            def on_release(key):
                try:
                    # F2 释放处理
                    if key == pynput_keyboard.Key.f2 and not self.auto_mode:
                        if self.button_release_callback:
                            self.button_release_callback()
                            self.update_button_status("按住说话")
                except Exception as e:
                    self.logger.error(f"键盘事件处理错误: {e}")

            self.keyboard_listener = pynput_keyboard.Listener(
                on_press=on_press,
                on_release=on_release
            )
            self.keyboard_listener.start()
            
            # 检查键盘监听器是否成功启动
            if not self.keyboard_listener.is_alive():
                self._show_permission_error()
                self.keyboard_listener_active = False
            else:
                self.keyboard_listener_active = True
                self.update_status("键盘监听已启动")
                
        except Exception as e:
            self.logger.error(f"键盘监听器启动失败: {e}")
            self._show_permission_error()
            self.keyboard_listener_active = False

    def _show_permission_error(self):
        """显示权限错误提示"""
        import platform
        
        error_msg = "键盘快捷键功能受限！"
        detail_msg = ""
        
        # 根据操作系统提供不同的指导
        if platform.system() == "Darwin":  # macOS
            detail_msg = (
                "macOS 需要辅助功能权限才能监听全局键盘事件。\n\n"
                "授权步骤：\n"
                "1. 打开系统设置 > 隐私与安全性 > 辅助功能\n"
                "2. 点击 + 按钮添加此应用程序\n"
                "3. 重启应用程序\n\n"
                "现在将使用内置键盘监听作为备用方案，但只有当应用窗口处于焦点状态时才有效。"
            )
        elif platform.system() == "Windows":
            detail_msg = (
                "Windows 可能需要管理员权限才能监听全局键盘事件。\n\n"
                "请尝试：\n"
                "1. 右键点击应用程序 > 以管理员身份运行\n"
                "2. 检查是否有防病毒软件阻止了键盘监听\n\n"
                "现在将使用内置键盘监听作为备用方案，但只有当应用窗口处于焦点状态时才有效。"
            )
        elif platform.system() == "Linux":
            detail_msg = (
                "Linux 可能需要特定权限才能监听全局键盘事件。\n\n"
                "请尝试：\n"
                "1. 确保已安装 X11 相关依赖\n"
                "2. 使用 sudo 运行应用程序\n\n"
                "现在将使用内置键盘监听作为备用方案，但只有当应用窗口处于焦点状态时才有效。"
            )
            
        # 在界面上显示错误信息
        self.update_status("键盘监听受限")
        
        # 创建弹窗提示用户
        import tkinter.messagebox as messagebox
        messagebox.showwarning(
            "键盘监听权限提示",
            f"{error_msg}\n\n{detail_msg}"
        )
        
        # 更新快捷键提示标签，指示当前状态
        self.update_queue.put(lambda: self.shortcut_label.config(
            text="快捷键: F2=说话 | F3=打断 | F4=开始对话 (仅窗口焦点时有效)",
            foreground="red"
        ))

    def stop_keyboard_listener(self):
        """停止键盘监听"""
        if self.keyboard_listener:
            self.keyboard_listener.stop()
            self.keyboard_listener = None

    def _setup_tkinter_key_bindings(self):
        """设置 tkinter 键盘绑定作为备用方案"""
        self.logger.info("使用 tkinter 键盘绑定作为备用")
        
        # 绑定 F2 键 - 按住说话（手动模式）
        self.root.bind("<KeyPress-F2>", lambda event: self._on_f2_key_press() if not self.auto_mode else None)
        self.root.bind("<KeyRelease-F2>", lambda event: self._on_f2_key_release() if not self.auto_mode else None)
        
        # 绑定 F3 键 - 打断
        self.root.bind("<KeyPress-F3>", lambda event: self._on_f3_key_press())
        
        # 绑定 F4 键 - 自动对话（自动模式）
        self.root.bind("<KeyPress-F4>", lambda event: self._on_f4_key_press() if self.auto_mode else None)
        
        # 更新状态
        self.update_status("使用内置键盘监听")
        
    def _on_f2_key_press(self):
        """F2 按键处理 - 通过 tkinter 绑定"""
        try:
            if self.button_press_callback:
                self.button_press_callback()
                self.manual_btn.config(text="松开以停止")
        except Exception as e:
            self.logger.error(f"F2 按键处理错误: {e}")
            
    def _on_f2_key_release(self):
        """F2 释放处理 - 通过 tkinter 绑定"""
        try:
            if self.button_release_callback:
                self.button_release_callback()
                self.manual_btn.config(text="按住说话")
        except Exception as e:
            self.logger.error(f"F2 释放处理错误: {e}")
            
    def _on_f3_key_press(self):
        """F3 按键处理 - 通过 tkinter 绑定"""
        try:
            # 更新按钮状态，提供视觉反馈
            self.abort_btn.config(text="打断中...", state="disabled")
            
            # 短暂延迟后恢复按钮状态
            self.root.after(1000, lambda: self.abort_btn.config(text="打断", state="normal"))
            
            # 调用回调函数
            if self.abort_callback:
                self.abort_callback()
        except Exception as e:
            # 发生错误时恢复按钮状态
            self.abort_btn.config(text="打断", state="normal")
            self.logger.error(f"F3 按键处理错误: {e}")
            
    def _on_f4_key_press(self):
        """F4 按键处理 - 通过 tkinter 绑定"""
        try:
            # 更新按钮状态，提供视觉反馈
            self.auto_btn.config(text="对话中...", state="disabled")
            
            # 短暂延迟后恢复按钮状态
            self.root.after(2000, lambda: self.auto_btn.config(text="开始对话", state="normal"))
            
            # 调用回调函数
            if self.auto_callback:
                self.auto_callback()
        except Exception as e:
            # 发生错误时恢复按钮状态
            self.auto_btn.config(text="开始对话", state="normal")
            self.logger.error(f"F4 按键处理错误: {e}")

    def update_auto_button_status(self, is_active: bool = False, text: Optional[str] = None):
        """更新自动对话按钮状态
        
        Args:
            is_active: 是否处于活动状态，True表示对话中，False表示待命
            text: 可选的按钮文本，如果不提供则根据is_active自动设置
        """
        if text is None:
            text = "对话中..." if is_active else "开始对话"
            
        state = "disabled" if is_active else "normal"
        
        self.update_queue.put(lambda: self.auto_btn.config(text=text, state=state))

    def update_abort_button_status(self, is_active: bool = False, text: Optional[str] = None):
        """更新打断按钮状态
        
        Args:
            is_active: 是否处于活动状态，True表示打断中，False表示待命
            text: 可选的按钮文本，如果不提供则根据is_active自动设置
        """
        if text is None:
            text = "打断中..." if is_active else "打断"
            
        state = "disabled" if is_active else "normal"
        
        self.update_queue.put(lambda: self.abort_btn.config(text=text, state=state))
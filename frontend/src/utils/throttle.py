import time
import functools
import logging
from typing import Callable, Optional, Any, TypeVar, cast

# 创建类型变量用于泛型函数类型
F = TypeVar('F', bound=Callable[..., Any])

def throttle(delay_seconds: float = 1.0) -> Callable[[F], F]:
    """
    创建一个节流装饰器，限制函数调用频率
    
    Args:
        delay_seconds: 节流时间（秒）
        
    Returns:
        装饰器函数
        
    Example:
        @throttle(2.0)
        def my_function():
            # 这个函数最多每2秒执行一次
            pass
    """
    def decorator(func: F) -> F:
        last_called = [0.0]  # 使用列表存储，以便在闭包中修改
        
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            current_time = time.time()
            if current_time - last_called[0] < delay_seconds:
                # 如果在节流时间内，直接返回
                return None
            
            last_called[0] = current_time
            return func(*args, **kwargs)
            
        return cast(F, wrapper)
    return decorator


def tk_throttle(delay_seconds: float = 1.0, 
                reset_callback: Optional[Callable[[], None]] = None,
                error_callback: Optional[Callable[[Exception], None]] = None) -> Callable[[F], F]:
    """
    专门为Tkinter设计的节流装饰器，包含错误处理和重置回调
    
    Args:
        delay_seconds: 节流时间（秒）
        reset_callback: 可选的重置回调函数，在节流结束时调用
        error_callback: 可选的错误处理回调函数
        
    Returns:
        装饰器函数
        
    Example:
        @tk_throttle(2.0, reset_callback=self._reset_button_state)
        def _on_button_click(self):
            # 按钮点击处理逻辑
            pass
    """
    def decorator(func: F) -> F:
        # 使用字典存储状态，以便在闭包中修改
        state = {
            'is_throttled': False,
            'timer': None
        }
        
        logger = logging.getLogger("Throttle")
        
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            # 获取self参数（如果是类方法）
            self_obj = args[0] if args else None
            
            # 如果正在节流中，直接返回
            if state['is_throttled']:
                return None
                
            # 设置节流状态
            state['is_throttled'] = True
            
            try:
                # 执行原始函数
                result = func(*args, **kwargs)
                
                # 设置定时器重置节流状态
                if hasattr(self_obj, 'after') and callable(self_obj.after):
                    # 如果是Tkinter对象，使用after方法
                    if state['timer'] is not None and hasattr(self_obj, 'after_cancel'):
                        self_obj.after_cancel(state['timer'])
                    state['timer'] = self_obj.after(
                        int(delay_seconds * 1000), 
                        lambda: _reset_throttle(self_obj)
                    )
                else:
                    # 否则使用普通定时器
                    time.sleep(delay_seconds)
                    _reset_throttle(self_obj)
                
                return result
                
            except Exception as e:
                # 发生错误时重置节流状态
                _reset_throttle(self_obj)
                
                # 调用错误处理回调
                if error_callback:
                    error_callback(e)
                else:
                    logger.error(f"节流函数执行错误: {e}")
                
                # 重新抛出异常
                raise
        
        def _reset_throttle(self_obj: Any) -> None:
            """重置节流状态"""
            state['is_throttled'] = False
            state['timer'] = None
            
            # 调用重置回调
            if reset_callback:
                reset_callback()
        
        return cast(F, wrapper)
    return decorator 
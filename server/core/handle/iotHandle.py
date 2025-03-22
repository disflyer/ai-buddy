import json
import uuid
from config.logger import setup_logging

TAG = __name__
logger = setup_logging()


class IotDescriptor:
    """
    A class to represent an IoT descriptor.
    Attributes:
    ----------
    name : str
        The name of the IoT descriptor.
    description : str
        A brief description of the IoT descriptor.
    properties : dict
        A dictionary containing properties of the IoT descriptor.
    methods : dict
        A dictionary containing methods of the IoT descriptor.
    -------
    """

    def __init__(self, name, description, properties, methods):
        self.name = name
        self.description = description
        self.properties = []
        self.methods = []

        # 根据描述创建属性
        for key, value in properties.items():
            # "volume":{"description":"当前音量 值","type":"number"}
            """
            等价于
            {
                'name': 名字,
                'description': 描述,
                'value': 0
            }
            """
            # setattr(self, key, {}) # 创建一个空字典, 名字是属性名
            property_item = globals()[key] = {}  # 创建一个空字典, 名字是属性名
            property_item['name'] = key
            property_item["description"] = value["description"]
            if value["type"] == "number":
                property_item["value"] = 0
            elif value["type"] == "boolean":
                property_item["value"] = False
            else:
                property_item["value"] = ""
            self.properties.append(property_item)

        # 根据描述创建方法
        for key, value in methods.items():
            # "SetVolume": {"description":"设置音量","parameters":{"volume":{"description":"0到100之间的整数","type":"number"}}}
            """
            等价于
            SetVolume = {
                `description`: 描述,
                `volume`: {
                    `description`: 描述,
                    `value`: 0
                }
            }
            """
            # setattr(self, key, {}) # 创建一个空字典, 名字是方法名
            method = globals()[key] = {}  # 创建一个空字典, 名字是方法名
            method["description"] = value["description"]
            method['name'] = key
            for k, v in value["parameters"].items():
                # 不同的参数解析
                method[k] = {}
                method[k]["description"] = v["description"]
                if v["type"] == "number":
                    method[k]["value"] = 0
                elif v["type"] == "boolean":
                    method[k]["value"] = False
                else:
                    method[k]["value"] = ""

            self.methods.append(method)


async def handleIotDescriptors(conn, descriptors):
    """处理IOT设备描述信息"""
    try:
        # 记录设备描述
        conn.iot_descriptors = descriptors

        # 生成设备描述的提示语
        devices = []
        all_traits = []
        for descriptor in descriptors.values():
            device_type = descriptor.get("type", "未知设备类型")
            device_name = descriptor.get("name", "未知设备名称")
            device_id = descriptor.get("id", str(uuid.uuid4()))
            
            traits = descriptor.get("traits", [])
            trait_names = []
            for trait in traits:
                trait_type = trait.get("type", "unknown")
                trait_name = trait.get("name", "未知特性")
                trait_names.append(f"{trait_name}({trait_type})")
                
                # 收集所有特性以便生成全局指令
                all_traits.append({
                    "device_name": device_name,
                    "device_id": device_id,
                    "trait_type": trait_type,
                    "trait_name": trait_name
                })
            
            trait_desc = "、".join(trait_names) if trait_names else "无特性"
            devices.append(f"{device_name}({device_type})，特性：{trait_desc}")

        # 生成总结提示
        prompt = f"我检测到以下智能设备:\n" + "\n".join(devices)
        
        # 添加全局指令
        if all_traits:
            global_commands = generate_global_commands(all_traits)
            if global_commands:
                prompt += "\n\n你可以通过以下指令控制这些设备:\n" + "\n".join(global_commands)
        
        conn.logger.bind(tag=TAG).info(f"IOT设备描述: {prompt}")
        
        # 回复确认信息
        response = {
            "type": "iot_ack",
            "message": "设备描述已接收",
            "session_id": conn.session_id
        }
        await conn.websocket.send_text(json.dumps(response))
        
    except Exception as e:
        conn.logger.bind(tag=TAG).error(f"处理IOT设备描述出错: {str(e)}")
        error_response = {
            "type": "error",
            "message": f"处理设备描述失败: {str(e)}",
            "session_id": conn.session_id
        }
        await conn.websocket.send_text(json.dumps(error_response))


async def handleIotStatus(conn, status):
    """处理IOT设备状态更新"""
    try:
        # 根据您的需要处理状态信息
        conn.logger.bind(tag=TAG).info(f"接收到IOT状态更新: {status}")
        
        # 回复确认信息
        response = {
            "type": "iot_status_ack",
            "message": "设备状态已更新",
            "session_id": conn.session_id
        }
        await conn.websocket.send_text(json.dumps(response))
        
    except Exception as e:
        conn.logger.bind(tag=TAG).error(f"处理IOT状态更新出错: {str(e)}")
        error_response = {
            "type": "error",
            "message": f"处理设备状态更新失败: {str(e)}",
            "session_id": conn.session_id
        }
        await conn.websocket.send_text(json.dumps(error_response))


def generate_global_commands(traits):
    """根据设备特性生成通用指令"""
    commands = set()
    
    # 为不同类型的特性生成指令
    for trait in traits:
        device_name = trait["device_name"]
        trait_type = trait["trait_type"]
        
        if trait_type == "onoff":
            commands.add(f"打开{device_name}")
            commands.add(f"关闭{device_name}")
        
        elif trait_type == "brightness":
            commands.add(f"调高{device_name}亮度")
            commands.add(f"调低{device_name}亮度")
            commands.add(f"把{device_name}调到50%亮度")
        
        elif trait_type == "colorsetting":
            commands.add(f"把{device_name}调成红色")
            commands.add(f"把{device_name}调成蓝色")
            commands.add(f"把{device_name}调成暖色")
        
        elif trait_type == "temperaturesetting":
            commands.add(f"把{device_name}温度调高")
            commands.add(f"把{device_name}温度调低")
            commands.add(f"把{device_name}温度设置为26度")
    
    return sorted(list(commands))

async def get_iot_status(conn, name, property_name):
    """
    获取物联网状态
    name: 设备名称 "Speaker"
    property_name: 属性名称 "volume"
    返回值: 属性值, 实际的属性有int, bool和str三种类型
    """
    for key, value in conn.iot_descriptors.items():
        if key == name:
            for property_item in value.properties:
                if property_item["name"] == property_name:
                    return property_item["value"]
    return None

async def send_iot_conn(conn, name, method_name, parameters):
    """
    发送物联网指令
    name: 设备名称 "Speaker"
    method: 方法 "SetVolume"
    parameters: 参数, 是一个字典 {"volume": 100}
    发送示例:
    {
        "type": "iot",
        "commands": [
            {
                "name" :  "Speaker",
                "method": "SetVolume",
                "parameters": {
                    "volume": 100
                    }
            }
        ]
    }
    """

    for key, value in conn.iot_descriptors.items():
        if key == name:
            # 找到了设备
            for method in value.methods:
                # 找到了方法
                if method["name"] == method_name:
                    await conn.websocket.send_text(json.dumps({
                        "type": "iot",
                        "commands": [
                            {
                                "name": name,
                                "method": method_name,
                                "parameters": parameters
                            }
                        ]
                    }))
                    return
    logger.bind(tag=TAG).error(f"未找到方法{method_name}")

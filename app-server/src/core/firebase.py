import firebase_admin
from firebase_admin import credentials
import os

def initialize_firebase():
    """初始化 Firebase Admin SDK"""
    if firebase_admin._apps:
        return  # 已经初始化过了
    
    # 检查是否在 Google Cloud 环境中
    # 方法1: 检查元数据服务器
    try:
        import requests
        response = requests.get(
            'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
            headers={'Metadata-Flavor': 'Google'},
            timeout=1
        )
        if response.status_code == 200:
            # 在 Google Cloud 环境中，使用默认应用凭据
            print("检测到 Google Cloud 环境，使用默认应用凭据")
            firebase_admin.initialize_app(options={
                'projectId': 'tinybuddy-8858a',
                'databaseURL': 'https://tinybuddy-8858a-default-rtdb.firebaseio.com/',
                'storageBucket': 'tinybuddy.appspot.com'
            })
            return
    except:
        pass
    
    # 方法2: 检查环境变量
    if os.getenv('GOOGLE_APPLICATION_CREDENTIALS'):
        print("使用 GOOGLE_APPLICATION_CREDENTIALS 环境变量")
        firebase_admin.initialize_app(options={
            'projectId': 'tinybuddy-8858a',
            'databaseURL': 'https://tinybuddy-8858a-default-rtdb.firebaseio.com/',
            'storageBucket': 'tinybuddy.appspot.com'
        })
        return
    
    # 方法3: 使用本地密钥文件（开发环境）
    service_account_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
        "secrets",
        "tinybuddy-8858a-firebase-adminsdk-fbsvc-597811bd7d.json"
    )
    
    if os.path.exists(service_account_path):
        print(f"使用本地服务账号密钥文件: {service_account_path}")
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred, {
            'projectId': 'tinybuddy-8858a',
            'databaseURL': 'https://tinybuddy-8858a-default-rtdb.firebaseio.com/',
            'storageBucket': 'tinybuddy.appspot.com'
        })
        return
    
    # 如果都不行，抛出错误
    raise RuntimeError("无法找到 Firebase 认证凭据")

# 初始化 Firebase
initialize_firebase() 
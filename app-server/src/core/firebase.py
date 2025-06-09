import firebase_admin
from firebase_admin import credentials
import os

# 获取服务账号密钥文件路径
service_account_path = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
    "secrets",
    "tinybuddy-8858a-firebase-adminsdk-fbsvc-597811bd7d.json"
)

# 初始化 Firebase Admin SDK
if not firebase_admin._apps:
    cred = credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred, {
        'projectId': 'tinybuddy-8858a',
        'databaseURL': 'https://tinybuddy-8858a-default-rtdb.firebaseio.com/',
        'storageBucket': 'tinybuddy.appspot.com'  # 如果需要使用 Firebase Storage
    }) 
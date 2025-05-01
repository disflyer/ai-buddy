import logging
import resend
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from src.core.config import settings

logger = logging.getLogger(__name__)

async def send_email(
    email_to: str,
    subject: str,
    template_name: str,
    template_data: dict | None = None,
) -> None:
    """
    发送邮件（通过 Resend）
    Args:
        email_to: 收件人邮箱
        subject: 邮件主题
        template_name: 模板名称
        template_data: 模板数据
    """
    # 构建邮件内容
    if template_name == "verification":
        html_content = f"""
        <html>
            <body>
                <p>您好！</p>
                <p>请点击以下链接验证您的邮箱：</p>
                <p><a href=\"{settings.FRONTEND_URL}/verify-email?token={template_data.get('token')}\">验证邮箱</a></p>
                <p>如果您没有注册账号，请忽略此邮件。</p>
            </body>
        </html>
        """
    elif template_name == "reset_password":
        html_content = f"""
        <html>
            <body>
                <p>您好！</p>
                <p>请点击以下链接重置您的密码：</p>
                <p><a href=\"{settings.FRONTEND_URL}/reset-password?token={template_data.get('token')}\">重置密码</a></p>
                <p>如果您没有请求重置密码，请忽略此邮件。</p>
            </body>
        </html>
        """
    else:
        raise ValueError(f"Unknown template name: {template_name}")

    # 初始化 Resend API Key
    resend.api_key = getattr(settings, "RESEND_API_KEY", None)
    if not resend.api_key:
        logger.error("Resend API Key 未配置，无法发送邮件")
        raise RuntimeError("Resend API Key 未配置")

    try:
        result = resend.Emails.send(
            {
                "from": f"{settings.EMAILS_FROM_NAME} <{settings.EMAILS_FROM_EMAIL}>",
                "to": [email_to],
                "subject": subject,
                "html": html_content,
            }
        )
        # SDK 是同步的，需用线程池或直接 await loop.run_in_executor（如需完全异步）
        # 这里直接调用，因发送量不大影响可忽略
        if not result or result.get("error"):
            logger.error(f"邮件发送失败: {result}")
            raise RuntimeError(f"邮件发送失败: {result}")
    except Exception as e:
        logger.exception(f"邮件发送异常: {e}")
        raise 
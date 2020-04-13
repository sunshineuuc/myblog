---
title: 使用PHPMailer发送邮件
date: 2020-03-27 20:59:31
tags:
- PHP
categories:
- 开发者手册
---

#### 引言 ####
本文通过一个开源的`PHPMailer`类库来实现邮件发送。PHPMailer 是一个强大的 PHP 编写的邮件发送类，使用它可以更加便捷的发送邮件，并且还能发送附件和 HTML 格式的邮件，同时还能使用`SMTP`服务器来发送邮件。
<!-- more -->
---

#### 部分服务器地址和端口 ####

在配置发送邮件服务器时会填写服务器地址和端口，而服务器地址不同的服务器的类型和不同的邮箱也不相同。下面参考[WordPress果酱](https://blog.wpjam.com/m/gmail-qmail-163mail-imap-smtp-pop3/)给出**Gmail**, **QMail**, **163邮箱**这三个常用邮箱的这些地址。

##### Exmail 的 IMAP/SMTP/POP3 地址 #####

| 服务器名称 | 服务器地址 | SSL协议端口 | 非SSL协议端口 |
| :-- | :-- | :-- | :-- |
| IMAP | imap.exmail.qq.com | 993 | - |
| SMTP | smtp.exmail.qq.com | 465 | - |
| POP3 | pop.exmail.qq.com | 995 | - |


##### QMail 的 IMAP/SMTP/POP3 地址 #####
QMail 的 IMAP/SMTP/POP3 协议默认是不开启的，你需要登陆到 QQ邮箱，然后到“设置” > “账户” 将其开启

| 服务器名称 | 服务器地址 | SSL协议端口 | 非SSL协议端口 |
| :-- | :-- | :-- | :-- |
| IMAP | imap.qq.com | 993 | 143 |
| SMTP | smtp.qq.com | 465或587 | 25 |
| POP3 | pop.qq.com | 995 | 110 |

##### Gmail 的 IMAP/SMTP/POP3 地址 #####
Gmail 的 IMAP/SMTP/POP3 协议默认都是开启，它的详细地址如下

| 服务器名称 | 服务器地址 | SSL协议端口 | 非SSL协议端口 |
| :-- | :-- | :-- | :-- |
| IMAP | imap.gmail.com | 993 | - |
| SMTP | smtp.gmail.com | 465 | - |
| POP3 | pop.gmail.com | 995 | - |

##### 163邮箱 的 IMAP/SMTP/POP3 地址 #####


| 服务器名称 | 服务器地址 | SSL协议端口 | 非SSL协议端口 |
| :-- | :-- | :-- | :-- |
| IMAP | imap.163.com | 993 | 143 |
| SMTP | smtp.163.com | 465或994 | 25 |
| POP3 | pop.163.com | 995 | 110 |

---

#### PHPMailer简单介绍 ####

下载地址：[PHPMailer](https://github.com/PHPMailer/PHPMailer)，部分功能举例:

- 在邮件中包含多个 TO、CC、BCC 和 REPLY-TO。
- 平台应用广泛，支持的 SMTP 服务器包括 Sendmail、qmail、Postfix、Gmail、Imail、Exchange 等等。
- 支持嵌入图像，附件，HTML 邮件。
- 可靠的强大的调试功能。
- 支持 SMTP 认证。
- 自定义邮件头。
- 支持 8bit、base64、binary 和 quoted-printable 编码。

#### 实现 ####
```php
defined('BASEPATH') or exit('No direct script access allowed');

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\SMTP;

class Notifications extends Api
{
    public function __construct()
    {
        parent::__construct();
    }

    public function email_test_get()
    {
        $mail = new PHPMailer(true);

        try {
            //Server settings

            /**
             *  SMTPDebug 输出信息级别
             *  关闭：DEBUG_OFF
             *  客户端信息：DEBUG_CLIENT
             *  服务器信息：DEBUG_SERVER
             * 所有信息：DEBUG_LOWLEVEL
             */
            $mail->SMTPDebug = SMTP::DEBUG_LOWLEVEL;

            //设定邮件编码，默认ISO-8859-1，如果发中文此项必须设置为 UTF-8
            $mail->CharSet ="UTF-8";

            // 使用SMTP
            $mail->isSMTP();

            // 发送服务器，比如：smtp.exmail.qq.com
            $mail->Host       = 'smtp.exmail.qq.com';

            // 使用SMTP认证
            $mail->SMTPAuth   = true;

            // 发件人账号/密码
            $mail->Username   = 'your_name@xxx.com';
            $mail->Password   = 'your_password';

            // 加密技术： tls or ssl
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;

            // SMTP服务器端口： SMTPS => 465  SMTP => 25
            $mail->Port       = 465;

            // 发件人账号及昵称
            $mail->setFrom('发件人地址', '发件人昵称');
            
            // 收件人账号及昵称
            $mail->addAddress('收件人地址', '收件人昵称');
            
            // 回复人地址和昵称
            $mail->AddReplyTo("邮件回复人地址","邮件回复人名称");
            
            $mail->isHTML(true); // true: 'text/html'  false: 'text/plain'
            
            // 标题
            $mail->Subject = '你的奖品已到账，请查收';
            
            // 正文
            $mail->Body    = '...';
            $mail->AltBody = '为了查看该邮件，请切换到支持 HTML 的邮件客户端';

            //$mail->AddAttachment("images/phpmailer.gif"); // 附件

            // 发送
            $mail->send();
            echo 'Message has been sent';
        } catch (Exception $e) {
            echo "Message could not be sent. Mailer Error: {$mail->ErrorInfo}";
        }
    }
}
```

---
title: Wireshark抓包分析TCP的三次握手与四次挥手
date: 2019-12-05 20:27:07
tags:
- 网络
categories:
- 开发者手册
---

#### 引言 ####

`《计算机网络》中说三次握手的目的是防止已失效的连接请求又传送到服务器端，因而产生错误`，这句话怎么理解？ 为什么连接的建立需要三次握手，而断开需要四次挥手？

<!-- more -->
首先介绍下tcp报头中的标识符，tcp的连接与断开由标识符来进行控制的。

#### 标志符 ####

`tcp`的标识符占12位，`前三位为保留位，需要置为0`；剩下九个标志符各占一位，依次为`NS`、`CWR`、`ECE`、`URG`、`ACK`、`PSH`、`RST`、`SYN`和`FIN`。下面通过抓包来分析tcp的三次握手、四次挥手和过程中使用的部分标志位。
<img src="simple-wireshark-tcp-flags/20191205215043.png" class="nofancybox" />

如上图，目前可用的标志位有9位，下面是[维基百科](https://zh.wikipedia.org/wiki/%E4%BC%A0%E8%BE%93%E6%8E%A7%E5%88%B6%E5%8D%8F%E8%AE%AE)对于九位标志符的介绍：
- NS—ECN-nonce。ECN显式拥塞通知（Explicit Congestion Notification）是对TCP的扩展，定义于RFC 3168（2001）。ECN允许拥塞控制的端对端通知而避免丢包。ECN为一项可选功能，如果底层网络设施支持，则可能被启用ECN的两个端点使用。在ECN成功协商的情况下，ECN感知路由器可以在IP头中设置一个标记来代替丢弃数据包，以标明阻塞即将发生。数据包的接收端回应发送端的表示，降低其传输速率，就如同在往常中检测到包丢失那样。
- CWR—Congestion Window Reduced。
- ECE—ECN-Echo有两种意思，取决于SYN标志的值。
- URG—为1表示高优先级数据包，紧急指针字段有效。
- ACK—为1表示确认号字段有效
- PSH—为1表示是带有PUSH标志的数据，指示接收方应该尽快将这个报文段交给应用层而不用等待缓冲区装满。
- RST—为1表示出现严重差错。可能需要重新创建TCP连接。还可以用于拒绝非法的报文段和拒绝连接请求。
- SYN—为1表示这是连接请求或是连接接受请求，用于创建连接和使顺序号同步
- FIN—为1表示发送方没有数据要传输了，要求释放连接。

---

#### 三次握手 ####

<img src="simple-wireshark-tcp-flags/20191206210409.png" class="nofancybox" title="第一次握手" />
上图为由客户端请求的第一次握手的TCP报头信息，大概内容是：

- 标志位`SYN`置`1`，告诉端口1688的服务器我要请求建立连接。
- 并产生一个序号(`Sequence number`)等于`0`， 表示这个包的第一个字节的序号为`0`。`在TCP传输中，每一个字节都是有序号的，从0开始。通过序号的方式保存数据的顺序，接收端接受到之后进行重新排列成为需要的数据`。还有一个作用就是万一发生数据包丢失，也可以通过这个序号知道丢失的是哪个包。
- 状态：客户端进入`SYN_SENT`状态。

---

<img src="simple-wireshark-tcp-flags/20191206211847.png" class="nofancybox" title="第二次握手" />
上图为由服务端响应的第二次握手的TCP报头信息，大概内容是：

- 标志位`ACK`(Acknowledgment)置`1`，表示确认号字段`Acknowledgment number`有效。
- 标志位`SYN`置`1`，表示接受连接请求。
- 将请求包序号`Sequence number`的值 `+ 1`赋给确认号`Acknowledgment number`，即`Acknowledgment number`值为`1`。
- 产生一个序号(`Sequence number`)等于`0`， 表示响应包的第一个字节的序号为`0`。
- 状态：服务器进入`SYN_RCVD`状态，握手结束。

---

<img src="simple-wireshark-tcp-flags/20191206213846.png" class="nofancybox" title="第三次握手" />
上图为由客户端响应的第三次握手的TCP报头信息，大概内容是：

- 标志位`ACK`(Acknowledgment)置`1`，表示确认号字段`Acknowledgment number`有效。
- 将响应包序号`Sequence number`的值 `+ 1`赋给确认号`Acknowledgment number`，即`Acknowledgment number`值为`1`。
- 序列号`Sequence number`的值为响应包中确认号`Acknowledgment number`的值。
- 状态：客户端收到服务端的响应包后检查确认号`Acknowledgment number`是否为请求序号`Sequence number`的值 + 1，标志位`ACK`是否为1，如果正确则客户端进入`ESTABLISHED`状态。
- 状态：<font color="red">服务器收到这个tcp数据包之后检查确认号`Acknowledgment number`是否为响应序号`Sequence number`的值 + 1，标志位`ACK`是否为1，如果正确则客户端进入`ESTABLISHED`状态，否则继续等待！</font>

---

#### 为什么是三次握手而不是二次握手 ####

为了实现可靠数据传输， TCP 协议的通信双方， 都必须维护一个序列号， 以标识发送出去的数据包中， 哪些是已经被对方收到的。 三次握手的过程即是通信双方相互告知序列号起始值， 并确认对方已经收到了序列号起始值的必经步骤，如果只是两次握手， 至多只有连接发起方的起始序列号能被确认， 另一方选择的序列号则得不到确认。

--- 

#### SYN攻击 ####

了解了三次握手之后，有这么一种情况，当当客户端收到服务器的响应之后，即第二次握手之后如果客户端不发送响应给服务器，也就是说不进行第三次握手。这种情况下服务器会继续发送给客户端的响应包，即继续第二次握手。

SYN 攻击指的是，攻击客户端在短时间内伪造大量不存在的IP地址，向服务器不断地发送SYN包，服务器回复确认包，并等待客户的确认。由于源地址是不存在的，服务器需要不断的重发直至超时，这些伪造的SYN包将长时间占用未连接队列，正常的SYN请求被丢弃，导致目标系统运行缓慢，严重者会引起网络堵塞甚至系统瘫痪。SYN 攻击是一种典型的 DoS/DDoS 攻击。

---

#### 客户端的一次http通信 ####

##### 请求 #####

<code>HTTP协议</code>作为应用层协议其下层协议是tcp，也就是说http数据包时通过tcp协议进行传输的。这里客户端发送了一个http请求，紧接着服务端返回一个tcp数据包。下面来看详细过程：

<img src="simple-wireshark-tcp-flags/20191207115012.png" class="nofancybox" title="客户端HTTP请求包" />

上图为端口号为50765的客户端使用postman发起http请求的请求包信息，由上图可以发现：

- 序列号`Sequence number`的值为`1`，表示该数据包的第一个字节序号为`1`。
- 确认号`Acknowledgment number`的值为`1`，这里跟上个包发送的值是一样的，因为这里由第二次握手服务端的`Sequence number` + 1得来的。
- `TCP Segment Len`的值为365表示该数据包的长度为365个字节，也就是说下个包的`Sequence number`的值应该为`366`。
- 因为请求包信息365个字节，一个tcp包就能发送完，，因此这里将标志位`Push`置`1`，告诉服务端所有信息都在这一个包里，不用等下个包了。
- 标志位`ACK`(Acknowledgment)置`1`，表示确认号字段`Acknowledgment number`有效。

---

服务端收到来自客户端的HTTP请求包后，会发送一个tcp包告诉客户端已经收到这个包了。tcp包的信息如下图所示：
<img src="simple-wireshark-tcp-flags/20191207120536.png" class="nofancybox" title="服务端返回tcp确认信息" />

- 首先将标志位`ACK`(Acknowledgment)置`1`，表示确认号字段`Acknowledgment number`有效。
- 将htp请求包中序号`Sequence number`的值加上请求包的长度，即`366`赋给确认号`Acknowledgment number`。
- 然后自己的序号的`Sequence number`值还是1。
- `TCP Segment number`的值为0表示下个包的`Sequence number`的值应该还是1。
- 客户端收到这个包之后将`确认号跟http请求包的序号 + 1判断是否相等`，`标志位ACK是否为1`，确认没问题就不需要再次发送了。

---

##### 响应 #####

服务端返回http请求的应答后，接着返回http响应：
<img src="simple-wireshark-tcp-flags/20191207132836.png" class="nofancybox" title="服务端返回tcp确认信息" />

- 首先将标志位`ACK`(Acknowledgment)置`1`，表示确认号字段`Acknowledgment number`有效。
- 序列号`Sequence number`的值为`1`，表示该数据包的第一个字节序号为`1`。
- 因为响应表包信息1248个字节，[理论上一个tcp包能发送1400字节左右](http://www.ruanyifeng.com/blog/2017/06/tcp-protocol.html)，因此一个tcp包就能发送完，，因此这里将标志位`Push`置`1`，告诉客户端所有信息都在这一个包里，不用等下个包了。
- `TCP Segment Len`的值为1248表示该数据包的长度为1248个字节，也就是说下个包的`Sequence number`的值应该为`1249`。

--- 

客户端收到来自服务端的HTTP响应包后，会发送一个tcp包告诉服务端已经收到这个包了。tcp包的信息如下图所示：
<img src="simple-wireshark-tcp-flags/20191207135046.png" class="nofancybox" title="服务端返回tcp确认信息" />

- 首先将标志位`ACK`(Acknowledgment)置`1`，表示确认号字段`Acknowledgment number`有效。
- 将htp响应包中序号`Sequence number`的值 + 1，即`1249`赋给确认号`Acknowledgment number`。
- 然后自己的序号的`Sequence number`值是366。
- `TCP Segment number`的值为0表示下个包的`Sequence number`的值应该还是366。
- 服务端收到这个包之后将`确认号跟http响应包的序号 + 1判断是否相等`，`标志位ACK是否为1`，确认没问题就不需要再次发送了。

---

#### TCP Keep-Alive ####

HTTP 1.1默认设置头部字段Connection: keep-alive
```text
Hypertext Transfer Protocol
    GET /blog?limit=5&page=1 HTTP/1.1
    x-api-key: 68a33910d61a1c9fb44fc0b91349db612bb64873
    Authorization: Basic Y29kZWlnbml0ZXI6Y29kZWlnbml0ZXJAY29kZWlnbml0ZXI=
    User-Agent: PostmanRuntime/7.18.0
    Accept: */*
    Cache-Control: no-cache
    Postman-Token: 86ec238a-f5de-43e2-9ceb-d5d9774af078
    Host: localhost:1688
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    
    [Full request URI: http://localhost:1688/blog?limit=5&page=1]
    [HTTP request 1/1]
    [Response in frame: 4839]
```
客户端收到响应后，如果长时间没有再次请求，一段时间后服务端会给连接对端发送一个探测包。如图：

<img src="simple-wireshark-tcp-flags/20191207154352.png" class="nofancybox" title="客户端进行tcp连接探测" />

TCP KeepAlive 的基本原理是，隔一段时间给连接对端发送一个探测包，如果收到对方回应的 ACK，则认为连接还是存活的，在超过一定重试次数之后还是没有收到对方的回应，则丢弃该 TCP 连接。

有关TCP Keepalive的详细内容可参照[TCP-Keepalive-HOWTO](http://www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/)

---

#### 四次挥手 ####

如果长时间没有再次请求，服务端将发起断开连接请求，触发四次挥手。

<img src="simple-wireshark-tcp-flags/20191207160723.png" class="nofancybox"  title="第一次挥手"/>

上图为由服务端发起的第一次挥手的TCP报头信息，大概内容是：

- 标志位`FIN`置1，要求释放连接。
- 标志位`ACK`(Acknowledgment)置`1`，表示确认号字段`Acknowledgment number`有效。
- 序号`Sequence number`值为1249。
- 确认号`Acknowledgment number`值为366。
- 发送完毕后，服务端进入 **FIN_WAIT_1** 状态。

---

<img src="simple-wireshark-tcp-flags/20191207162141.png" class="nofancybox" title="第二次挥手" />

上图为客户端发起的第二次挥手（即给服务器发送一个应答）的TCP报头信息：

- 标志位`ACK`(Acknowledgment)置`1`，表示确认号字段`Acknowledgment number`有效。
- 序号`Sequence number`值为366，`TCP Segment Len`的值为0，表示下次发送时序号不变。
- 确认号`Acknowledgment number`值为1250。
- 发送完毕后， 客户端端进入 **CLOSE_WAIT** 状态，表明自己接受到了服务端关闭连接的请求，但还没有准备好关闭连接。服务器收到这个确认包之后进入**FIN_WAIT_2**状态，等待客户端关闭连接。

---

<img src="simple-wireshark-tcp-flags/20191207162404.png" class="nofancybox" title="第三次挥手" />

上图为客户端发起的第三次挥手的TCP报头信息：

- 标志位`ACK`(Acknowledgment)置`1`，表示确认号字段`Acknowledgment number`有效。
- 标志位`FIN`置1，表示客户端已准备好关闭连接，向服务端发送结束连接请求。
- 序号`Sequence number`值为366。
- 确认号`Acknowledgment number`值为1250。
- 发送完毕后， 客户端端进入 **LAST_ACK** 状态，等待来自服务端的最后一个ACK。服务端收到客户端的关闭请求后进入**TIME_WAIT**状态

---

<img src="simple-wireshark-tcp-flags/20191207162516.png" class="nofancybox" title="第四次挥手" />

上图为服务端发起的第四次挥手的TCP报头信息：

- 标志位`ACK`(Acknowledgment)置`1`，表示确认号字段`Acknowledgment number`有效。
- 序号`Sequence number`值为1250。
- 确认号`Acknowledgment number`值为367。
- 发送完毕后，如果客户端收到这个确认包则关闭连接并进入**CLOSED**状态，服务器等待了某个固定时间（两个最大段生命周期，2MSL，2 Maximum Segment Lifetime）之后，没有收到客户端的 ACK ，认为客户端已经正常关闭连接，于是自己也关闭连接，进入 CLOSED 状态。

---

#### 为什么是四次挥手 ####

跟数据传输有关，客户端跟服务端在数据传输的过程中都负责接受数据跟发送数据，接受和发送都需要对停止做声明：

1. 服务端发起关闭连接请求，表明自己不再发送数据了，但是还是可以接受数据的。
2. 客户端收到关闭连接请求后，发送应答，表明客户端需要检查是否有数据需要发送给服务端。
3. 等客户端确认数据发送完成后，再次发送关闭连接应答，表明可以关闭连接了。
4. 服务端收到关闭应答后，关闭连接。

---

#### 参考链接 ####

[凭啥TCP连接要三次握手、四次挥手？](https://juejin.im/post/5d23510cf265da1ba84ab4e7)
[TCP 协议](https://hit-alibaba.github.io/interview/basic/network/TCP.html?q=)
[HTTP 的 Keep-Alive模式](https://blog.51cto.com/zxtong/1788252)

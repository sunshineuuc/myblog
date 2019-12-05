---
title: wireshark抓包分析tcp部分标志位的作用
date: 2019-12-05 20:27:07
tags:
- 网络
categories:
- web学习笔记
---

#### 引言 ####

`tcp`的标识符占12位，`前三位为保留位，需要置为0`；剩下九个标志符各占一位，依次为`NS`、`CWR`、`ECE`、`URG`、`ACK`、`PSH`、`RST`、`SYN`和`FIN`。下面通过抓包来分析tcp的三次握手、四次挥手和过程中使用的部分标志位。

<!-- more -->

#### 标志位 ####

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


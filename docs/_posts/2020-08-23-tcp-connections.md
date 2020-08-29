---
layout: post
title: TCP 长连接的最大个数
date: '2020-08-23 18:00:00 +0800'
categories: networking
math: true
---

提个问题，单机单网卡最大对某个特定服务器 TCP 长连接的最大个数是多少？

和平时一样，我们假设客户端是 Linux。这可能不是一个生造出来的问题，想一想，如果我们希望设计一个支持长连接的代理服务器呢？如果有海量的客户端希望连接被代理的服务器呢？或者说我们希望为用户提供实时的消息服务呢？这是一种 c1000k 问题。

我们从 TCP 协议开始，慢慢往外推，到操作系统直到硬件。看看一路上都有哪些限制。我们可以假设服务器是个怪物，它在 TCP 的框架下面可以有无穷的计算能力和带宽，各种资源取之不尽用之不竭。那么问题到了 TCP。

# TCP

## 数据库问题

有人说，这是个数据库问题。因为 TCP 实现为了区别 TCP 连接，用了个四元组标记每个 TCP 报文

- source ip: 32 bit for IPv4
- source port: 16 bit
- destination ip: 16 bit (fixed)
- destination port: 32 bit for IPv4 (fixed)

所以这四个数字合起来，就是数据库的复合主键。其中，目标服务的 IP 和端口都是固定的，所以我们只能从客户端这边发掘潜力：

### source ip

用 `iproute2` 可以为同一块网卡添加多个 IP 地址。理论上说，这就是 $$2^{32}$$ 个地址。

``` shell
ip addr add <ip>/<network> dev <interface>
```

但是要细究的话，IPv4 有很多特殊的地址段是不能使用或者使用上有限制的。如果服务器是对公网开放的，那么我们作为客户端就不能使用外部地址，只能用那些本地的地址，比如 `192.168.x.x` 或者 `127.x.x.x` 这些。如果使用 NAT/PAT 这类技术在内部实现 IP 复用，那么就需要把 NAT 设备的限制考虑进去了。不管怎么样，数量级差不多是这个。

### source port

对于特定目标地址，本地端口可以选择的区间是由 [net.ipv4.ip_local_port_range][2] 决定的。

``` shellsession
$ cat /proc/sys/net/ipv4/ip_local_port_range
32768	60999
```

对于给定的目标地址，以及给定的本地 IP，可以发出的连接数量就是本地端口区间的大小。所以单个本地 IP 最多可以产生 65535 个 TCP 连接。为了打破这个限制，我们必须为网卡添加多个虚拟 IP。满打满算，这就是 $$2^{32+16}$$ 个链接，约为 281万亿。打个比方，我想开个公司，先从员工的工号的编码方式开始计划！嗯，就用 IPv4 的地址和 16 位的端口号来吧，所以，我的公司最多支持 281万亿个员工。这个思路扩展性很好，很强大！但是每个人都得发工资啊，我陷入了沉思……

## TCP 的运行时开销

### 什么是 TCP 连接

我们熟知的三次握手就能建立一个 TCP 连接

1. SYN
1. 等待对方回应 SYN/ACK
1. 最后回答 ACK

一旦双方完成这个规定的礼仪，就可以说这个连接建立了。一旦两边接上头，剩下的事情就是运行时的开销。

### 系统 TCP 协议栈

如果服务使用系统的 TCP 协议栈，那么每个连接都需要占用一个文件描述符。回忆一下 `send()` 和 `recv()`，它们的第一个参数是 `socket`，而`socket` 可不就是个 `fd` 嘛。所以操作系统文件描述符的最大值，这个全局的 [设置][1] 是 `fs.file-max`。在我的 RHEL8 上，它的值是 `19603816`，接近两千万了。如果我们希望用单进程实现这个服务，还需要改 `ulimit -n` 的限制。当然，如果内存够大，多操作系统或者用容器化的实现，以及用多进程的实现都可以越过这些限制。代价就是更多的额外开销。

另外，还需要关注协议栈用到的缓冲区，看看 `net.ipv4.tcp_wmem` 和 `net.ipv4.tcp_rmem`，在 RHEL8 上，它们的缺省大小分别是 85K 和 16K。设置都有三组数字，分别是下限、缺省值和上限。以及 `net.ipv4.tcp_mem`，它控制着整个系统中所有 TCP 缓冲区的总大小的上限。这个设置表示的是内存页的数量，有三组数字，分别是下限、警戒值和上限。如果 TCP 缓冲空间总使用量达到上限之前，TCP 就会开始减少每个 TCP 连接缓冲区的分配。一旦达到上限，TCP 实现就开始丢包，希望减轻对内存系统的压力。

``` shellsession
$ grep . /proc/sys/net/ipv4/tcp*mem
/proc/sys/net/ipv4/tcp_mem:2295903	3061204	4591806
/proc/sys/net/ipv4/tcp_rmem:4096	87380	6291456
/proc/sys/net/ipv4/tcp_wmem:4096	16384	4194304
```

所以缺省设置下，最多使用 17G 内存，可以同时支持二百万以上的长连接。

Linux 下新的防火墙是使用 netfilter 实现的，如果开启了防火墙那么还需要关注 

- `net.ipv4.ip_conntrack_max`
- `net.ipv4.netfilter.ip_conntrack_max`

netfilter 维护着一张哈希表用来跟踪所有的 TCP 连接，所以如果这张表放不下新的 TCP 连接，TCP 就会开始丢包。

### 用户态 TCP 协议栈

### 带宽

需要估计所有连接中活跃的比例，并且需要了解活跃连接需要的带宽是多少。

### 内存

前面如果使用系统的 TCP/IP 栈，就需要为每个连接保证 `tcp_rmem.min` + `tcp_wmem.min` 的空间。


[1]: https://www.kernel.org/doc/Documentation/sysctl/fs.txt
[2]: https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt

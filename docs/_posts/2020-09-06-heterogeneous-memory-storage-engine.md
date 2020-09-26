---
layout: post
title: 'Heterogeneous-Memory Storage Engine'
date: '2020-09-06 16:02:52 +0800'
categories: kvstore
published: false
---

HSE -- 异构内存存储引擎。是镁光在 2020 年开源的存储引擎。所谓异构，就是同时使用不同种类 NAND 设备，根据其延迟和容量等特性，组合搭配，达到最好的效能。但是效能是个比较复杂的概念，不同的应用对性能的要求也不一样，有的侧重容量，有的侧重延迟，有的侧重并发。我觉得他们会提供几种不同的预设好的 profile，方便用户选择。

是一个在内核态基础设施，由两个部分组成

- Mpool
- HSE

# Mpool: Object Storage Media Pool

Mpool 负责对接下面的 NAND 块设备，包括传统的 SSD、ZNS 或者 PMEM。而它对外的接口是一种叫做 mpool 的设备，同时提供了两种写操作，专门用来访问 mpool 设备：

- 以 block 为单位的覆盖写操作。很自然这是由 flash 的特性决定的。
- append-only 的写操作。可以看出来这种操作是对 ZNS 量身定制的。这些操作是通过叫做 `mlog` 的对象表达的。

## MBlock

`MBlock` 支持以 block 为单位的操作。


## MLog

`Mlog` 支持流式的操作：
  * append. 给个 iovec，支持同步和异步。
  * read. 把 cursor 往前移动。
  * rewind. 倒带。把 cursor 往后移动。
  * sync. 确保落盘。

## MDC

MDC 即 MetaData Container。

- 管理的方式类似 LVM。创建举个例子
 1. 

Mpool 的 block 的大小在创建的时候指定，[文档][2]建议的大小是 32MB。有意思的是，``mpool list`` 有[一列][3]是 volume 的健康情况。在 mpool 的例子里面，mpool 并不是直接从物理块设备创建出来的，它是从 LVM 卷创建的。

* media class
 - staging: 活动区，初始接收数据的地方。或者用来保存热数据。
 - capacity: 主存储区，或者保存冷数据的地方。

## mlog



[1]: https://github.com/hse-project/mpool/wiki
[2]: https://github.com/hse-project/hse/wiki/Configure-Storage#configure-an-mpool
[3]: https://github.com/hse-project/hse/wiki/Configure-Storage#view-the-mpool

---
id: 329
title: 300TB of ELK
date: 2016-02-16T23:55:09+00:00
author: George Beech
layout: revision
guid: http://brokenhaze.com/blog/2016/02/16/328-revision-v1/
permalink: /2016/02/16/328-revision-v1/
---
I've been meaning to write this post for a while. A few years ago we decided that we needed a better centralized logging solution. The design goal at the time was to build a solution big enough that we wouldn't have to think about it for a while. One that was able to hold our growing web logs, as well as centralizing all logs from our enviroment - Windows, Linux, network. 

After some research we decided that an ELK stack would fit the bill for us. We started to take a look at what we had and estimate our needs for the next five years. Then we looked at the available hardware out there to run this on. We ended up settling on a set of servers that would give us good redundancy, and 300TB of storage. 
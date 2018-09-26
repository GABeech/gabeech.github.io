---
id: 328
title: 300TB of ELK
date: 2016-03-29T22:39:23+00:00
author: George Beech
layout: post
guid: http://brokenhaze.com/blog/?p=328
permalink: /?p=328
categories:
  - Uncategorized
---
I've been meaning to write this post for a while. A few years ago we decided that we needed a better centralized logging solution. The design goal at the time was to build a solution big enough that we wouldn't have to think about it for a while. One that was able to hold our growing web logs, as well as centralizing all logs from our enviroment - Windows, Linux, network. 

After some research we decided that an ELK stack would fit the bill for us. We started to take a look at what we had and estimate our needs for the next five years. Then we looked at the available hardware out there to run this on. We ended up settling on a set of servers that would give us good redundancy, and 300TB of storage. 

Alright, so a 300TB ELK setup. That seems a bit ... uhh insane you say? Why yes it is a little bit. But we have a reason for our madness! We wanted to not only put all of our operational logs into here, but shove all of our web logs into ELK. And we get a few web requests. 
---
id: 334
title: A History of the Stack Network Infrastructure
date: 2016-02-21T18:41:37+00:00
author: George Beech
layout: revision
guid: http://brokenhaze.com/blog/2016/02/21/330-revision-v1/
permalink: /2016/02/21/330-revision-v1/
---
<h1>Preamble</h1>
My co-worker, and sometimes partner in crimes against computers Nick Craver has decided to do a comprehensive dive into what we are currently doing with our technology, our setup, and how things are run today. I've recently started thinking that it's very cool to write about what we are doing today, but at the same time it is equally interesting - at least to me - how we got there. 

How to grow your infrastructure is not something you do in a vacuum. Each decision is a choice, and from that choice you close off some options and open up others. Each of our choices along the way has lead to what we are doing today. 

I want to try and put some perspective on what we have done with our network infrastructure. I am doing most of this from memory, so some things may not be fully fleshed out. We have written a lot about what we have done, but we haven't written everything. There have been points that our infrastructure has just magically changed between blog posts. 

<h1> In the beginning</h2> 

The stack infrastructure has grown slowly over these last, we have had a couple of forklift upgrades. More than a couple of data center moves. And there have been many decisions along the way that go us to where we are. 

I've had to do some spelunking here, since the earliest incarnations of the Stack Overflow network infrastructure are from before my time at the company. 

The first indications publicly are from a <a href=http://blog.stackoverflow.com/2009/12/stack-overflow-rack-glamour-shots/>Stack Overflow blog post</a> by Jeff, talking about the hardware upgrade. This post is from December, 2009 so that is where we will start our journey!

I can't speak to the reasoning behind these switches, since I wasn't here yet, but my guess is "Affordable, they work, we don't need something crazy." Then, shortly after that there is a discussion of <a href="http://blog.stackoverflow.com/2010/01/stack-overflow-network-configuration/">the network infrastructure</a> in January, 2010. From which I am going to borrow the network diagram. 

<a href="http://brokenhaze.com/blog/wp-content/uploads/2016/02/stack-overflow-network-diagram.png" rel="attachment wp-att-332"><img src="http://brokenhaze.com/blog/wp-content/uploads/2016/02/stack-overflow-network-diagram-300x235.png" alt="stack-overflow-network-diagram" width="300" height="235" class="alignright size-medium wp-image-332" /></a> 

As you can see, it is a pretty simple network layout. Nothing fancy, not trying to be something that it is not. I'm going to be honest that philosophy still permeiates everything we do today. We build everything as simple as we can to and build out as we need to. 
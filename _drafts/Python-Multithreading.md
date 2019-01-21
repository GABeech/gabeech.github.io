---
layout: post
title: Python and simple multiprocessing
author: George Beech
categories:
  - Python
  - Operations
  - APIs
comments: false
---

I recently spent some time working with Python to get some data transfered from an older ticketing system to a newer one. It was you basic pull data down, do a bit of transformation and then push data up to the new system. Not a very complicated piece of code, mostly just dealing with understanding the two different REST APIs, and making requests.

After I got the initial code written and did a test run against a queue with about 80 tickets that needed to be migrated over - which took around 30 minutes - I figured that was probably good. After all, this was a piece of code that would only run a few times and then the old system would be shut down. My next run was a test run against a queue that needed 2000 tickets imported. That one, well that one took 10 hours. While once again that would probably be ok. Script a loop and let the import run over a weekend to get all the queues done.

And then my coworker said "oh it'll take that long that's kind of slow." Challenge. Accepted.

## Let's look at the code

This isn't an actual copy of the code that I was actually working with, but a good approximation to illistrate what I did to speed things up. 

```python
import json
import requests

class ticket:
  def __init__(ticketData):
    self.attr1
    self.attr2
  def process(self):
    ''' We do all the stuff to process the tickets here '''
  def getJSON(self):
    return "JSON_HERE"
  def getAttachments(self):
    aList = requests.get(attachementList)
    for a in aList:
      requests.get(a.url)

def getTicketsQueue(queueName):
  myHeaders = {Auth: "blah"}
  uri = "http://ticketserver/queue/" + queueName
  res = requests.get(uri, headers=myHeaders)
  retVal = []
  for t in res:
    retVal.append(ticket(t))
  return retVal
def createNewTicket(ticket):
  myHeaders = {Auth: "blah"}
  uri = "http://newticketserver/ticket/create"
  requests.post(uri, headers=myHeaders, data=ticket.getJSON())

tickets = getTicketsQueue()
for ticket in tickets:
  ticket.process()
  createNewTIcket(ticket)
```

Ok, simple. Runs serially and gets the job done. Now how do we speed this up? Well let's multi-thread it! In C# I would just use `async` and probably a few `Parallel.For()` loops and call it a day. After spending a bit of time looking here are just a few of the options I found. (note: I spent way more time researching _how_ to do parallel processing in python that I should have)

* joblib
* Multiprocess
  * Processes
  * Queues
  * Pools
* asyncio

I skipped joblib as it seemed a bit more involved than I wanted for a throw away script. I tried `asyncio` and `aiohttp` they where ok, and probably would have worked if I had coded with them from the start. But, I didn't and still got stuck in very hard to manage serial operations.

## Pools

After reading through the documentation, I thought that Pools would be the simplest way to bolt on a bit of parallel processing to what I had. I took a bit of work, and a lot of research but I finally ended up using them. 

## First try with Pools

This is about what I ended up my first pass at pools. Honestly, there wasn't a whole lot of improvement since I got stuck with serial code. 

```python
import json
import requests
from multiprocessing import Pool

class ticket:
  def __init__(ticketData):
    self.attr1
    self.attr2
  def process(self):
    ''' We do all the stuff to process the tickets here '''
  def getJSON(self):
    return "JSON_HERE"
  def getAttachments(self):
    aList = requests.get(attachementList)
    for a in aList:
      requests.get(a.url)

def getTicketsQueue(queueName):
  myHeaders = {Auth: "blah"}
  uri = "http://ticketserver/queue/" + queueName
  res = requests.get(uri, headers=myHeaders)
  retVal = []
  for t in res:
    retVal.append(ticket(t))
  return retVal
def createNewTicket(ticket):
  myHeaders = {Auth: "blah"}
  uri = "http://newticketserver/ticket/create"
  requests.post(uri, headers=myHeaders, data=ticket.getJSON())

def process(ticket):
  ticket.process()
  createnewTicket(ticket)

if __name__ == "__main__":
  with Pool(20) as workerPool:
    tickets = getTicketsQueue()
    res = workerPool.map(process,tickets)
```

This code was a bit faster. What it is doing telling python to use 20 workers (and, if I"m understanding it correctly run them each in thier own process) and pass each item in your iterable (the second argument) to your function (the first argument).

This spead things up a bit, but there is still many places that can run slowly.

## Pools in Pools

Let's make this a bit faster? We have some more places that can be parallel-ized!

```python
import json
import requests
from multiprocessing import Pool

class ticket:
  def __init__(ticketData):
    self.attr1 = ''
    self.attr2 = ''
    self.attachments = []
  def process(self):
    details = requests.get(url, headers)
  def getJSON(self):
    return "JSON_HERE"
  def _getAttachment(self, uri):
    res = requests.get(uri)
    return res
  def getAttachments(self):
    aList = requests.get(attachementList)
    with Pool(20) as aPool:
      result = aPool.map_async(this._getAttachement, aList)
      return result.get()

def getTicketsQueue(queueName):
  myHeaders = {Auth: "blah"}
  uri = "http://ticketserver/queue/" + queueName
  res = requests.get(uri, headers=myHeaders)
  retVal = []
  for t in res:
    retVal.append(ticket(t))
  return retVal
def createNewTicket(ticket):
  myHeaders = {Auth: "blah"}
  uri = "http://newticketserver/ticket/create"
  requests.post(uri, headers=myHeaders, data=ticket.getJSON())

def process(ticket):
  ticket.process()
  

if __name__ == "__main__":
  with Pool(20) as workerPool:
    tickets = getTicketsQueue()
    res = workerPool.map(process,tickets)
```

Great! This should take care of most of the issues.

But, wait we have an error. A daemonized process can't spawn a new process. Crap. We can either rewrite all the code to use processes, and have a global pool, an queueing, and this is getting a bit too complicated. What can we do? 

## Threadpooling

There is a really, really hard to find part of the multiprocessing library calld a `ThreadPool` it implements the same functions as `Pool` but does them in threads instead of new processes. This solves the issue!

And with one small trick we can even do this with only chaning one line of code!

We just need to change our import a little. From `from multiprocessing import Pool` to `from multiprocessing import ThreadPool as Pool` bam. Massive speed increase with not a whole lot of effort.
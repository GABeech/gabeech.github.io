---
id: 203
title: How Stack Exchange gets the most out of HAProxy
date: 2014-03-25T16:39:33+00:00
author: George Beech
layout: post
guid: http://brokenhaze.com/blog/?p=203
permalink: /2014/03/25/how-stack-exchange-gets-the-most-out-of-haproxy/
dsq_thread_id:
  - "2516882669"
categories:
  - haproxy
  - infrastructure
  - stack exchange
  - SysAdmin
comments: true
---
At Stack Exchange we like to two two, well no three things. One, we love living on the bleeding edge and making use of awesome new features in software. Two, we love configuring the hell out of everything we run which leads to three - getting the absolute most performance out of the software that we run.
<!--more-->
HAProxy is no exception to this. We have been running HAProxy since just about day one. We have been on the 1.5dev branch of code since almost the day it came out.

Of course most people would ask why you would do that? You open yourself up to a whole lot of issues with dev code. The answer of course is there are features that we want in this dev code. The less selfish answer is that we want to make the internet a better place for everyone. What better way to do that then running bleeding edge code and finding the issues for you?

I'm going to go through our HAProxy setup and how we are using the features. I would highly recommended reading through the <a href="http://haproxy.1wt.eu/#docs"> HAProxy documentation</a> for the version you are running. There is a ton of good information in there.

<a href="http://brokenhaze.com/blog/wp-content/uploads/2014/03/front_end_se.png"><img src="http://brokenhaze.com/blog/wp-content/uploads/2014/03/front_end_se-149x300.png" alt="front_end_se" width="149" height="300" class="alignleft size-medium wp-image-246" style="border: 0; padding-right 2px"/></a>

<a href="http://brokenhaze.com/blog/wp-content/uploads/2014/03/HAProxy-Flow-ERD.png"><img src="http://brokenhaze.com/blog/wp-content/uploads/2014/03/HAProxy-Flow-ERD-232x300.png" alt="HAProxy Flow - ERD" width="232" height="300" class="alignleft size-medium wp-image-254" style="border: 0; padding-left 2px"/></a>

This is a high level overview of what our network looks like from the cloud to the web front ends. Yes, there is a lot more to us serving you a request, but this is enough for this post.

The basics are that a request comes into our network from the internet. Once it passes our edge routers it goes on to our load balencers. These are CentOS 6 linux boxes running HAProxy 1.5dev. The request comes into our HAProxy load balencers and then depending on what tier that they come into are processed and sent to a backend. After the packet makes it's way through HAProxy it gets routed to one of the web servers in our IIS farm. 

One of the reasons that HAProxy is so damn good at what it does is that is it single minded, as well as (mostly) single threaded. This has lead it to scale very very well for us. One of the nice things about the software being single threaded is that we can buy a decent sized multi-core server and as things need more resources we just split them out to their own tier which is another HAProxy instance, using a different core. 

Things get a bit more interesting with SSL as there is a multi-threaded bit to that to be able to handle the transaction overhead there. Going deeper into the how of the threading of HAProxy is out of the scope of this post though, so I'll just leave it at that. 



Phew, we've got the introductory stuff out of the way now. Let's dive into what our HAProxy config actually looks like!

The first bit is our global defaults, and some setup - users, a bit of tuning, and some other odds and ends. All of these options are very well documented in the HAProxy docs, so I won't bore you by explaining what each one of them do. 

For this post all but one example (our websocket config) comes out of what we call "Tier 1" this is our main tier, it's where we server the Q&A sites and other critical services out of. 

[code autolink="false"]
userlist stats-auth
    group admin users &lt;redacted&gt;
    user supa_dupa_admin insecure-password &lt;redacted&gt;
    group readonly users &lt;redacted&gt;
    user cant_touch_this insecure-password &lt;redacted&gt;

global
    daemon
    stats socket /var/run/haproxy-t1.stat level admin
    stats bind-process 1
    maxconn 100000
    pidfile /var/run/haproxy-t1.pid
    log 127.0.0.1 local0
    log 10.7.0.17 local0
    tune.bufsize 16384
    tune.maxrewrite 1024
    spread-checks 4
    nbproc 4

defaults
    errorfile 503 /etc/haproxy-shared/errors/503.http
    errorfile 502 /etc/haproxy-shared/errors/502.http
    mode http
    timeout connect 15s
    timeout client 60s
    timeout server 150s
    timeout queue 60s
    timeout http-request 15s
    timeout http-keep-alive 15s
    option redispatch
    option dontlognull
    balance source
[/code]

Nothing all that crazy here, some tweaks for scale, setting up some users, timeouts, logging options and default balance mode. Generally you want to tune the <pre>maxconn</pre> and your timeout values size to your environment and your application. Other than that the defaults should work for 98% of the people out there. 

Now that we have our defaults setup, lets look a little deeper into the really interesting parts of our configuration. I will point out things that we use that are only available in 1.5dev as I go. 

First, our SSL termination. We used to use Nginx for our SSL termination but as we grew our deployment of SSL. We knew that SSL support was coming to HAProxy, so we waited for it to come out then went in whole hog. 

[code]
listen ssl-proxy-1
    bind-process 2 3 4
    bind 198.51.100.1:443 ssl crt /etc/haproxy-shared/ssl/wc-san.pem
    bind 198.51.100.2:443 ssl crt /etc/haproxy-shared/ssl/wc-san.pem
    bind 198.51.100.3:443 ssl crt /etc/haproxy-shared/ssl/wc-san.pem
    bind 198.51.100.4:443 ssl crt /etc/haproxy-shared/ssl/wc-san.pem
    bind 198.51.100.5:443 ssl crt /etc/haproxy-shared/ssl/misc.pem
    bind 198.51.100.6:443 ssl crt /etc/haproxy-shared/ssl/wc-san.pem
    bind 198.51.100.7:443 ssl crt /etc/haproxy-shared/ssl/wc-san.pem
    bind 198.51.100.8:443 ssl crt /etc/haproxy-shared/ssl/wc-san.pem
    bind 198.51.100.9:443 ssl crt /etc/haproxy-shared/ssl/wc-san.pem
    bind 198.51.100.10:443 ssl crt /etc/haproxy-shared/ssl/misc.pem
    mode tcp
    server http 127.1.1.1:80 send-proxy
    server http 127.1.1.2:80 send-proxy
    server http 127.1.1.3:80 send-proxy
    server http 127.1.1.4:80 send-proxy
    server http 127.1.1.5:80 send-proxy

    maxconn 100000
[/code]

**This is a 1.5dev feature.**

[![HAProxy - Core Detail - New Page](http://brokenhaze.com/blog/wp-content/uploads/2014/03/HAProxy-Core-Detail-New-Page-300x171.png)](http://brokenhaze.com/blog/wp-content/uploads/2014/03/HAProxy-Core-Detail-New-Page.png)

Once again, this is a pretty simple setup the gist of what is going on here, is that we setup a listener on port 443. It binds to the specified IP addresses as an SSL port using the specified certificate file in [PEM format](http://serverfault.com/questions/9708/what-is-a-pem-file-and-how-does-it-differ-from-other-openssl-generated-key-file) specifically the full chain including the private key. This is actually a very clean way to setup SSL since you just have one file to manage, and one config line to write when setting up an SSL endpoint.

The next thing it does is set the target server to itself (127.0.0.1,2,3 etc) using the `send-proxy` directive which tell the proccess to use the proxy protocol so that we don't lose some of that tasty information when the packet gets shipped to the plain http front end.

**Now hold on a second! Why are you using multiple localhost proxy connections?!** Ahh, good catch. Most people probably won't run into this, but it's because we are running out of source ports when we only use one proxy connection. We ran into something called source port exhaustion. The quick story is that you can only have ~65k ip:port to ip:port connections. This wasn't an issue before we started using SSL since it we never got close to that limit.

What happened when we started using SSL? Well we started proxying a large amount of traffic via 127.0.0.1. I mean we do have a feeewww more than 65k connections.

```
Total: 581558 (kernel 581926)
TCP:   677359 (estab 573996, closed 95478, orphaned 1237, synrecv 0, timewait 95475/0), ports 35043
```

So the solution here is to simply load balance between a bunch of ip's in the 127.0.0.0/8 space. Giving us ~65k more source ports per entry.


The final thing I want to point out about the SSL front end is that we use the `bind-process` directive to limit the cores that that particular front end is allowed to use. This allows us to have multiple HAProxy instances running and not have them stomp all over eachother in a multi-core machine.

Our HTTP Fronend
----------------

The real meat of our setup is our http frontend. I will go through this piece by piece and at the end of this section you can see the whole thing if you would like.

```
frontend http-in
    bind 198.51.100.1:80 name stackexchange
    bind 198.51.100.2:80 name careers
    bind 198.51.100.3:80 name careers.sstatic.net
    bind 198.51.100.4:80 name openid
    bind 198.51.100.5:80 name misc
    bind 198.51.100.6:80 name stackexchange
    bind 198.51.100.7:80 name careers
    bind 198.51.100.8:80 name careers.sstatic.net
    bind 198.51.100.9:80 name openid
    bind 198.51.100.10:80 name misc
    bind 127.1.1.1:80 accept-proxy name http-in
    bind 127.1.1.2:80 accept-proxy name http-in
    bind 127.1.1.3:80 accept-proxy name http-in
    bind 127.1.1.4:80 accept-proxy name http-in
    bind 127.1.1.5:80 accept-proxy name http-in
    bind-process 1
```

Once again, this is just setting up our listeners, nothing all that special or interesting here. Here is where you will find the binding that our SSL front end sends to with the `accept-proxy` directive. Additionally, we give them a name so that they are easier to find in our monitoring solution.

```
stick-table type ip size 1000k expire $expire_time store gpc0,conn_rate($some_connection_rate)

## Example from HAProxy Documentation (not in our actual config)##
# Keep track of counters of up to 1 million IP addresses over 5 minutes
# and store a general purpose counter and the average connection rate
# computed over a sliding window of 30 seconds.
stick-table type ip size 1m expire 5m store gpc0,conn_rate(30s)
```

The first interesting piece is the `stick-table` line. What is going on here is we are capturing connection rate for the incoming IPs to this frontend and storing them into gpc0 (General Purpose Counter 0). The example from the HAProxy docs on [stick-tables](http://cbonte.github.io/haproxy-dconv/configuration-1.5.html#4-stick-table) explains this pretty well.

```
    log global
    

    capture request header Referer               len 64
    capture request header User-Agent            len 128
    capture request header Host                  len 64
    capture request header X-Forwarded-For       len 64
    capture request header Accept-Encoding       len 64
    capture response header Content-Encoding     len 64
    capture response header X-Page-View          len 1
    capture response header X-Route-Name         len 64
    capture response header X-Account-Id         len 7
    capture response header X-Sql-Count          len 4
    capture response header X-Sql-Duration-Ms    len 7
    capture response header X-AspNet-Duration-Ms len 7
    capture response header X-Application-Id     len 5
    capture response header X-Request-Guid       len 36
    capture response header X-Redis-Count        len 4
    capture response header X-Redis-Duration-Ms  len 7
    capture response header X-Http-Count         len 4
    capture response header X-Http-Duration-Ms   len 7
    capture response header X-TE-Count           len 4
    capture response header X-TE-Duration-Ms     len 7

rspidel ^(X-Page-View|Server|X-Route-Name|X-Account-Id|X-Sql-Count|X-Sql-Duration-Ms|X-AspNet-Duration-Ms|X-Application-Id|X-Request-Guid|X-Redis-Count|X-Redis-Duration-Ms|X-Http-Count|X-Http-Duration-Ms|X-TE-Count|X-TE-Duration-Ms):
```

We are mostly doing some setup for logging here. What is happening, is that as a request comes in or leaves we capture some specific headers using `capture response` or `capture request` depending on where the request is coming from. HAProxy then takes those headers and inserts them into the syslog message that is sent to our logging solution. Once we have captured the headers that we want on the response we remove them using `rspidel` to strip them from the response sent to the client. `rspidel` uses a simple regex to find and remove the headers.

The next thing that we do is to setup some ACLs. I'll just show a few examples here since we have quite a few.

```
acl source_is_serious_abuse src_conn_rate(http-in) gt $some_number
acl api_only_ips src -f /etc/haproxy-shared/api-only-ips
acl is_internal_api path_beg /api/
acl is_area51 hdr(host) -i area51.stackexchange.com
acl is_kindle hdr_sub(user-agent) Silk-Accelerated
```

I would say that the first ACL here is one of the more important ones we have. Remember that stick-table we setup earlier? Well this is where we use that. It adds your IP to the ACL `source_is_serious_abuse` if your IP's connection rate in gpc0 is greater than `$some_number`. I will show you what we do with this shortly when I get to the routing in the config file.

The next few acl's are just examples of different ways that you can setup acl's in HAProxy. For example, we check to see if your user agent has 'Silk-Accelerated' in the UA. If it does we put you in the `is_kindle` acl.

Now that we have those acl's setup, what exactaly do we use them for?

```
    tcp-request connection reject if source_is_serious_abuse !source_is_google !rate_limit_whitelist
    use_backend be_go-away if source_is_abuser !source_is_google !rate_limit_whitelist
```

The first thing we do is deal with those connections that make it onto our abuse ACLs. The first one just deny's the connection if you are bad enough to hit our serious abuse ACL - unless you have been whitelisted or are google. The second one is a soft error that throws up a 503 error if you are just a normal abuser - once again unless you are google or whitelisted.

The next thing we do is some request routing. We send different requests to different server backends.

```
    use_backend be_so_crawler if is_so is_crawler
    use_backend be_so_crawler if is_so is_crawler_ua
    use_backend be_so if is_so
    use_backend be_stackauth if is_stackauth
    use_backend be_openid if is_openid

    default_backend be_others
```

What this is doing is matching against ACLs that where setup above, and sending you to the correct backend. If you don't match any of the ACLs you get sent to our default backend.

An Example Backend
------------------

Phew! That's a lot of information so far. We really do have a lot configured in our HAProxy instances. Now that we have our defaults, general options, and front ends configured what does one of our backends look like?

Well they are pretty simple beasts. Most of the work is done on the front end.

```
backend be_others
    mode http
    bind-process 1
    stick-table type ip size 1000k expire 2m store conn_rate($some_time_value)
    acl rate_limit_whitelist src -f /etc/haproxy-shared/whitelist-ips
    tcp-request content track-sc2 src
    acl conn_rate_abuse sc2_conn_rate gt $some_value
    acl mark_as_abuser sc1_inc_gpc0 gt $some_value
    tcp-request content reject if conn_rate_abuse !rate_limit_whitelist mark_as_abuser

    stats enable
    acl AUTH http_auth(stats-auth)
    acl AUTH_ADMIN http_auth_group(stats-auth) $some_user
    stats http-request auth unless AUTH
    stats admin if AUTH_ADMIN
    stats uri /my_stats
    stats refresh 30s

    option httpchk HEAD / HTTP/1.1\r\nUser-Agent:HAProxy\r\nHost:serverfault.com

    server ny-web01 10.7.2.101:80 check
    server ny-web02 10.7.2.102:80 check
    server ny-web03 10.7.2.103:80 check
    server ny-web04 10.7.2.104:80 check
    server ny-web05 10.7.2.105:80 check
    server ny-web06 10.7.2.106:80 check
    server ny-web07 10.7.2.107:80 check
    server ny-web08 10.7.2.108:80 check
    server ny-web09 10.7.2.109:80 check
```

There really isn't too much to our back ends. We setup some administrative auth at the beginning. The next thing we do is, I think the most important part. We specify with the `option httpchk` where we want to connect when doing a check on the host to see if it's up.

In this instance we are just checking '/' but a lot of our back ends have a '/ping' route that gives more information about how the app is performing for our out monitoring solutions. To check those routes we simply change 'HEAD /' to 'HEAD /ping'

Final Words
-----------

Man, that we sure a lot of information to write, and process. But using this setup has giving us a very stable, scalable and flexible load balancing solution. We are quite happy with the way that this is all setup, and has been running smoothly for us.

**Update 9/21/14:** For those curious you can [look at the full, sanitized tier one config](https://gist.github.com/GABeech/eb88933bf49cd82ceab0) we use.
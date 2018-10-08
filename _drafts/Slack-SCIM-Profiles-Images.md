---
layout: post
title: Updating User Profile Photos via Slack SCIM API
author: George Beech
categories:
  - Powershell
  - Operations
  - APIs
comments: false
---

## The Challenge

I was recently tasked with updating our Slack instance with user photos that are stored in AD.
This should be a relatively simple thing to put into place (ignoreing the fact our existing Identity tooling should just take care of it). Sadly, it wasn't as simple as I thought.

<!--more-->

Getting the photos from AD was the easy part, the hard part was getting them into slack in a reasonable manner. First, lets look at the problem set:

1. User Photos are stored in AD as a byte array (jpg image format)
2. I need to be able to upload these photos to Slack without user involvement
3. I need to maintain the confidentiality of the photos (we didn't want someone to just be able to scrap a photo of every user in our org)
4. I needed to minimize the number of operations against the Slack API (narrator: he broke slack)

### The process as it was

The first hurdle I needed to jump was figuring out just what API calls I needed to use to access the user profiles for all of our users. Which, is not as [easy as you would think](https://medium.com/slack-developer-blog/getting-started-with-slacks-apis-f930c73fc889). The problem I ran into immediately is that the user/profile api does not let you access random profiles. If you realize the API was built for a public app directory, and not internal enterprise apps this makes sense.

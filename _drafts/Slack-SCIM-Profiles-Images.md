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

Getting the photos from AD was the easy part, the hard part was getting them into slack in a reasonable manner. First, lets look at the problem set: 

1. User Photos are stored in AD as a byte array (jpg image format)
2. I need to be able to upload these photos to Slack without user involvement
3. I need to maintain the confidentiality of the photos (we didn't want someone to just be able to scrap a photo of every user in our org)
4. I needed to minimize the number of operations against the Slack API (narrator: he broke slack)

```powershell
{% include_relative scripts/test.ps1 %}
```
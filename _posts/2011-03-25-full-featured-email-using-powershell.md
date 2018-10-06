---
id: 22
title: Full Featured Email using powershell
date: 2011-03-25T12:22:51+00:00
author: George Beech
layout: post
guid: http://brokenhaze.com/blog/?p=22
permalink: /2011/03/25/full-featured-email-using-powershell/
dsq_thread_id:
  - "2528341740"
categories:
  - Powershell
---
**Note: This is copied (thank you wayback machine) from a previous incarnation of my blog. I was very sad when I realized this post was gone, then very happy when wayback machine had it** A little while ago i spent a lot of time trying to figure out how to send an email that fulfilled the following requirements: Multiple Recipients Attached File Meaningful Subject Sent without an external executable Thanks to powershell's ability to access .Net libraries, this is a fairly simple, however not quite so well explained - at least that i could find - process. Let us start simply, with the basic SMTPClient Object, and setting the Server Variables, settings, etc. The most basic way to configure your server is to simple create a.Net System.Net.Mail.smtpClient object, and set the email server hostname, taking the defaults.
<!--more-->

```powershell
$SMTPClient = new-object System.Net.Mail.smtpClient
$SMTPClient.host = ""
```

Simple, right? Then lets get a little bit more complicated. Lets send an email to a host that requires authentication. To do this, we are going to need another .Net object: The NetworkCredential Object from there we can set the domain, user, and password, set these values on our SMTPClient.

```powershell
$Credentials = new-object System.Net.networkCredential
$Credentials.domain = ""
$Credentials.UserName = ""
$Credentials.Password = ""
$SMTPClient.Credentials = $Credentials
```

The above code is fairly self explainitory, if you were to display $SMTPClient (Just type $SMTPClient on the console) before and after when you set the Credentials property you can see that is has been set. There are a few other options that you can set on the SMTPClient object, including Port, and SSL to see all that you can do issue

```powershell
$SMTPClient | gm
```

Now, we have the Client setup, we want to configure message that we want to send. This will include setting up the Subject, To, From, and Body. What I do to send mail is use an overload of the SMTPClient object that lets us use System.Net.Mail.MailMessage to send the mail, it gives you ALOT more control over your message. First lets get ourselves another .Net Object, the MailMessage Object.

```powershell
$MailMessage = new-object System.Net.Mail.MailMessage
```

The next thing I want to do is Setup my addresses The To: and From: addresses are yet another .Net object System.Net.Mail.MailAddress. Here is how you set those up, it is very simple and all you really need is the constructor which is overloaded. You can setup your address in the following two ways.

```powershell
$Address = new-object System.Net.Mail.MailAddress("user@domain.com")
$Address = new-object System.Net.Mail.MailAddress("user@domain.com", "Display Name")
```

Either was you want, you need to create at least two one for your sender, one for your recipient. After we get those options out of the way, we just need to do the final setup on our message. That will include setting up the Subject, Body, and feeding it the To: and From: Addresses we already created.

```powershell
$MailMessage.Subject = "Hello World!"
$MailMessage.Body = "String Body"
$MailMessage.Sender = $Sender
$MailMessage.From = $Sender
$MailMessage.To.add($Recipient)
```

Why, you ask, am I setting the $Senter twice, the Sender property is the Displayed From Address, while the From property is the repy-to address. You can send an email with an html body just put the code in your Body string, all you have to do is specify the boolean IsHtmlBody property.

```powershell
$MailMessage.IsHtmlBody = $true
```

Now, how about adding an attachment. This is done very simply with another MailMessage property set to the .Net Attachements object

```powershell
$Attachment = new-object System.Net.Mail.Attachment("")
$MailMessage.Attachements.Add($Attachment) 
```

That is all there is to that. There is one last thing we have to do to get this mail off and on it's way. Simply. Send It!

```powershell
$SMTPClient.Send($MailMessage)
```
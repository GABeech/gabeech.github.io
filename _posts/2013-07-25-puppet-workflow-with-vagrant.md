---
id: 164
title: Puppet Workflow with Vagrant
date: 2013-07-25T10:00:40+00:00
author: George Beech
layout: post
guid: http://brokenhaze.com/blog/?p=164
permalink: /2013/07/25/puppet-workflow-with-vagrant/
dsq_thread_id:
  - "3437554303"
categories:
  - puppet
  - Tools
---
I've spent a good deal of my time working with puppet over the last few years. And like most other things I've spent some time trying to optimize my workflow to avoid the annoying things. Just like anything else developing a good workflow for puppet has taken some time and I'd like to share the workflow that we have come to use over at Stack Exchange that seems to be pretty-darn-good.
<!--more-->
Until recently our puppet dev workflow wasn't horrible, however was a bit painful. Normally you would see something like (pg version):

commit -> wait for CI to pick up commit -> build failed -> damn -> fix typo -> commit -> wait for build -> build failed -> grrr -> fix new error -> commit ... and on and on.

> O, that way madness lies; let me shun that;
> No more of that.
> -William Shakespeare

Our new way of doing things is much, much saner. Which has in general raised team spirits!

### The Dev Tier

We currently use Vagrant to do local dev work on new modules, and changes production modules. I have to say once it clicked that I can use Vagrant for puppet it was like that first sip of rocket fueled coffee in the morning. Everything suddenly became clear.

We have a vagrant file that uses two boxes - one is the client and the other is the server. They are actually seperate boxes. The client one is a box standard CentOS 6.4 minimal install. The server is the same but with all the puppetmaster bits all setup and ready to go. This includes Apache + Passenger, and all the CA goodness. It's in a state just before the first run of puppetmasterd that creates the certificates.

First let's look at the master config. There isn't much special here but I do want to point out few things.

```none
# Setup the Puppet master
  config.vm.define :master do |master|
    master.vm.box = "centos64-puppetm"
    master.vm.box_url = "http://&lt;internal_server&gt;/vagrant/vagrant-sei-puppetm-centos.x64.vb.box"
    master.vm.hostname = "master.local"
    master.vm.synced_folder "../../puppet-dev", "/etc/puppet"
    master.vm.synced_folder "../../scripts", "/root/scripts"
    master.vm.network :private_network, ip: "172.28.19.20"
    master.vm.provision :shell, :path =&gt; "master.sh"
    # Customize the actual virtual machine
    master.vm.provider :virtualbox do |vb|
      # Uncomment this, and adjust as needed to add memory to vm
      vb.customize ["modifyvm", :id, "--memory", 2048]
      # Because Virtual box is stupid - change the default nat network
      vb.customize ["modifyvm", :id, "--natnet1", "192.168.0.0/16"]
    end
  end
```

The first two highlights there are setting up synced folders. One is to the **local** puppet development repo on your disk, and the second is to a folder of our utility scripts.

This is actually the real magic. with our puppet development folder on our local _host machine_ mounted at /etc/puppet this allows us to work in our local enviroment with all of our editing tools that we have come to love, and all we have to do is simply save our work and it is active in our Vagrant environment.

The next thing you will see highlighted is the master.vm.provision stanza. This is telling vagrant to use a shell (bash) based provisioner and to run the script that if finds in ./ on the host as it is starting up. There are a [bunch of provisioners](http://docs.vagrantup.com/v2/provisioning/) available for Vagrant. I'm using a shell provisioner here because I just want to do a couple of very very basic things to get the box in working order.

```bash
service ntpd stop
ntpdate pool.ntp.org
service ntpd start
service httpd stop
service puppetmaster start
service puppetmaster stop
service httpd start
```

As you can see, there is not much going on here. Syncing the time, stopping Apache/Passenger, starting then immediately stopping puppetmater to generate the certificates, then starting Apache/Passenger back up and we are ready to go.

The last two lines are simply modify the base VM to add more memory (Vagrant defaults to allocating 512M) and changing the NAT IP. We had to do the second one because VirtualBox defaults to using 10.2.0.0/24 for the nat network - which is a production network for us.

Our client configuration is almost exactly the same except the puppet folder is synced to /root/puppet for convenience and it pulls a different box down.

The provisioning script is also very basic for the client.

```bash
echo "172.28.19.20 puppet" &gt;&gt; /etc/hosts
service ntpd stop
ntpdate pool.ntp.org
service ntpd start
service puppet stop
rm -rf /var/lib/puppet/ssl/
service puppet start
```

The two biggest pieces here are lines one and six. Line one adds a hosts entry for the master puppet server so the client can bootstrap itself. And the sixth line makes sure any certs that might have been there are destroyed and lets puppet recreate them.

You can expand below to see the full source of our Vagrantfile

```vagrant
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile which sets up one puppet master and one puppet client.
# Assumes "puppet-dev" and "scripts" repos are cloned into the same
# base directory.

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "centos64"

  # Setup the Puppet master
  config.vm.define :master do |master|
    master.vm.box = "centos64-puppetm"
    master.vm.box_url = "http://&lt;internal_server&gt;/vagrant/vagrant-sei-puppetm-centos.x64.vb.box"
    master.vm.hostname = "master.local"
    master.vm.synced_folder "../../puppet-dev", "/etc/puppet"
    master.vm.synced_folder "../../scripts", "/root/scripts"
    master.vm.network :private_network, ip: "172.28.19.20"
    master.vm.provision :shell, :path =&gt; "master.sh"
    # Customize the actual virtual machine
    master.vm.provider :virtualbox do |vb|
      # Uncomment this, and adjust as needed to add memory to vm
      vb.customize ["modifyvm", :id, "--memory", 2048]
      # Because Virtual box is stupid - change the default nat network
      vb.customize ["modifyvm", :id, "--natnet1", "192.168.0.0/16"]
    end
  end

  # Setup the Puppet client. You can copy and modify this stanza to allow for
  # multiple client, just change all instances of 'client1' to another term
  # such as 'client2'
  config.vm.define :client1 do |client1|
    client1.vm.box = "centos64"
    client1.vm.box_url = "http://&lt;internal_server&gt;/vagrant/vagrant-sei-centos64.x64.vb.box"
    client1.vm.hostname = "client1"
    # Make puppet-dev accessable from the client for easier copying.
    client1.vm.synced_folder "../../puppet-dev", "/root/puppet"
    client1.vm.network :private_network, ip: "172.28.19.21"
    #client1.vm.network :forwarded_port, guest: 8100, host: 8100
    client1.vm.provision :shell, :path =&gt; "client.sh"
    client1.vm.provider :virtualbox do |vb|
      # Uncomment this, and adjust as needed to add memory to vm
      vb.customize ["modifyvm", :id, "--memory", 2048]
      # Because Virtual box is stupid - change the default nat network
      vb.customize ["modifyvm", :id, "--natnet1", "192.168.0.0/16"]
    end
  end

  if false
    config.vm.define :client2 do |client2|
      client2.vm.box = "centos64"
      client2.vm.box_url = "http://ny-man02.ds.stackexchange.com/vagrant/vagrant-sei-centos64.x64.vb.box"
      client2.vm.hostname = "client2"
      # Make puppet-dev accessable from the client for easier copying.
      client1.vm.synced_folder "../../puppet-dev", "/root/puppet"
      client2.vm.network :private_network, ip: "172.28.19.22"
      client2.vm.provision :shell, :path =&gt; "client.sh"
      # Customize the actual virtual machine
      client2.vm.provider :virtualbox do |vb|
        # Uncomment this, and adjust as needed to add memory to vm
        vb.customize ["modifyvm", :id, "--memory", 2048]
        # Because Virtual box is stupid - change the default nat network
        vb.customize ["modifyvm", :id, "--natnet1", "192.168.0.0/16"]
      end
    end
  end

end
```

So, what exactly does doing a dev setup like this help you with? It keeps you from having to constantly push to your testing environment to test every change. Which is huge - especially when you have a habbit of missing typo's that puppet-lint doesn't catch. You can smoke test on a local VM and iterate extremely quickly. Avoid madness, don't spam internal chat with build messages. It's a win-win-win to me. For those that don't know my handle on the SE network is [Zypher](http://stackexchange.com/users/87602/zypher) ... so Nick is talking about me descending into madness.

[![puppet-madnexx](http://brokenhaze.com/blog/wp-content/uploads/2013/07/puppet-madnexx-1024x486.png)](http://brokenhaze.com/blog/wp-content/uploads/2013/07/puppet-madnexx.png)

### Test and Prod

I'm going to talk about the test and prod environments together here. The only functional difference between the two is the puppet module code that is run in those environments so for the purposes of this exercise they are the same.

What happens after you are done working locally and have a working change? Well that is simple, you push the change set(s) from your local clone to our mercurial server. You can obviously swap mercurial with any VCS system you like.

Once the changes have been pushed up the server, our CI Server (TeamCity) will pull the changes down and "build" them. Since nothing is really compiled with puppet what it is actually doing is running through a battery of tests, then if they pass it pushes the changes out to our puppet masters.

1. Run a bash script that checks the changeset against puppet validate
2. Run a bash script that generates the puppet docs for the changeset
3. Push the changes to the puppet master servers

We have bot in our internal chat that will post a message with the success/failure of the build and a link to the build info page inside TeamCity. Once you have a successful build then your change is live in Test or Prod depending on which repo you pushed to.

That's about it. There is nothing all that special or groundbreaking here. All the magic really happens at the local dev stage with Vagrant. The sanity checks on the server side before deployment are really just to make extra sure since you worked all the bugs out, right?

I'm sure that there is yet more room for improvement to our process but at this point i'm happy to say the decent into madness has been staved off for now.
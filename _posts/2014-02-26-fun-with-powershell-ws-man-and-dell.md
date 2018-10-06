---
id: 229
title: Fun With PowerShell, WS-MAN, and Dell Servers
date: 2014-02-26T22:17:46+00:00
author: George Beech
layout: post
guid: http://brokenhaze.com/blog/?p=229
permalink: /2014/02/26/fun-with-powershell-ws-man-and-dell/
dsq_thread_id:
  - "2824534198"
categories:
  - DevOps
  - Powershell
  - SysAdmin
---
Recently I've been playing with using the WS-MAN protocol to gather information (and eventually run updates) on our Dell servers. It has actually been a fairly insteresting project after I got through the pretty high learning curve to get started using WS-MAN.

First, what is WS-MAN? It's a management standard developed by the [DTMF](http://www.dmtf.org/standards/wsman). What it really boils down to is giving us the ability to access and manipulate CIM providers via HTTP calls.

One of the interesting things Dell did with their systems in the past two generations (Gen 11 and 12) is to add something they call the Life Cycle controller. They did not really make much information known on what you can do with it, or even how to really use it.
<!--more-->
Recently I have been exploring what you can do with the Life Cycle Controller. And, quite honestly, you can do a ton of good stuff with it. Everything from getting system information to setting boot options, all the way up to updating all of the firmware on your box. This is all done through the WS-MAN Protocol.

First I would suggest doing some reading so you can get the basic concepts of WS-MAN.

* [DTMF WS-MAN page](http://www.dmtf.org/standards/wsman)
* [Dell Article on scripting the LCC](http://en.community.dell.com/techcenter/b/techcenter/archive/2011/11/21/scripting-dell-idrac6-with-lifecycle-controller-remote-services.aspx)
* [Dell DCIM Library](http://en.community.dell.com/techcenter/systems-management/w/wiki/1906.dcim-library-profile.aspx)

Phew, got through all that?

Lets start off with a nice code snippet that I have been working on, and then step through what it is doing.

```powershell
$DELL_IDS = @{
    "20137" = "DRAC";
    "18980" = "LCC";
    "25227" = "DRAC";
    "28897" = "LCC";
    "159" = "BIOS"
    }

$pass = ConvertTo-SecureString "ThisIsMyPassword" -AsPlainText -Force
$creds = new-object System.Management.Automation.PSCredential ("root", $pass)
$wsSession = New-WSManSessionOption -SkipCACheck -SkipCNCheck

$svc_details = @{}

$base_subnet = "192.168.99."
$addrs = @(1..254)
foreach ($ip in $addrs)
{
    $base_subnet + $ip
    $s = [System.Net.Dns]::GetHostByAddress($base_subnet+$ip).HostName
&lt;code&gt;$fw_info = Get-WSManInstance 'cimv2/root/dcim/DCIM_SoftwareIdentity' -Enumerate -ConnectionURI https://$s/wsman -SessionOption $wsSession -Authentication basic -Credential $creds
$svr_info = Get-WSManInstance 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/root/dcim/DCIM_SystemView' -Enumerate -ConnectionURI https://$s/wsman -SessionOption $wsSession -Authentication basic -Credential $creds

$svc_details.Add($s, @{})
if($svr_info -eq $null)
{
    $svc_details[$s].Add(&amp;quot;Generation&amp;quot;, &amp;quot;unknown probably 11G&amp;quot;)
}
else
{
    $svc_details[$s].Add(&amp;quot;Generation&amp;quot;, $svr_info.SystemGeneration.Split(&amp;quot; &amp;quot;)[0])
}
foreach ($com in $fw_info)
{

    $DELL_IDS.ContainsKey($com.ComponentID)
    if($DELL_IDS.ContainsKey($com.ComponentID))
    {
        #need to see if I can update this to account for the different
        #way drac6 and 7's format this string
        $inst_state = $com.InstanceID.Split(&amp;quot;#&amp;quot;)[0].Split(&amp;quot;:&amp;quot;)[1]
        if (($inst_state -ne &amp;quot;PREVIOUS&amp;quot;) -AND ($inst_state -ne &amp;quot;AVAILABLE&amp;quot;))
        {
            $svc_details[$s].Add($DELL_IDS[$com.ComponentID], $com.VersionString)
        }
    }
}

}
```

The first part of this code is simply a hash table of dell component IDs and an associated easy-to-remember name matching them with the component. How did I get those? Well I queried the `cimv2/root/dcim/DCIM_SoftwareIdentity` namespace and parsed the output by hand to grab those IDs. They match up to BIOS, LCC v1, LCC v2, iDRAC 6 and iDRAC 7.

```powershell
$pass = ConvertTo-SecureString "ThisIsMyPassword" -AsPlainText -Force
$creds = new-object System.Management.Automation.PSCredential ("root", $pass)
$wsSession = New-WSManSessionOption -SkipCACheck -SkipCNCheck
```

This next section of code sets up our enviroment for `Get-WSManInstance`. First we need to convert our plaintext password into a secure string, then create a PSCredential object to use later so we don't have to enter our username and password over and over. Finally, we setup a new WS-MAN session options object so that it doesn't error out on the self signed certificates we are using. If you are using fully trusted certificates on your dracs you can skip this step and not specify the `-SessionOption $wsSession` flag later.

```powershell
$fw_info = Get-WSManInstance 'cimv2/root/dcim/DCIM_SoftwareIdentity' -Enumerate -ConnectionURI https://$s/wsman -SessionOption $wsSession -Authentication basic -Credential $creds
$svr_info = Get-WSManInstance 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/root/dcim/DCIM_SystemView' -Enumerate -ConnectionURI https://$s/wsman -SessionOption $wsSession -Authentication basic -Credential $creds
```

_Note_ You can specify either the DCIM Path or the schema, I'm showing both ways here. For the `$svr_info` variable `'cimv2/root/dcim/DCIM_SystemView'` would also work.

Now, we move on to the meat of what we are doing. These two lines grab the system information that we want to parse. The `$fw_info` contains an XML object that returns all of the install components as exposed by the DCIM_SoftwareIdentity endpoint, and the `$svr_info` variable contains an XML object that has some interesting system information - such as Server Generation, Express Service Code, Service Tag, and so on. I use these two pieces of information to parse out the Generation, DRAC, BIOS, and LCC firmware versions.

```powershell
#need to see if I can update this to account for the different&lt;/h1&gt;
#way drac6 and 7's format this string&lt;/h1&gt;

$inst_state = $com.InstanceID.Split("#")[0].Split(":")[1]
if (($inst_state -ne "PREVIOUS") -AND ($inst_state -ne "AVAILABLE"))
    {
        svc_details[$s].Add($DELL_IDS[$com.ComponentID], $com.VersionString)
    }
```

One last tricky bit. When you get back the versions that are installed, you will actually have two different versions. Once that is the active version and one that is the rollback version. Unfortunately you need to parse string to figure that out. And different DRACs use different string formats.

* Drac6: `DCIM:INSTALLED:PCI:14E4:1639:0236:1028:5.0.13`
* Drac7: `DCIM:INSTALLED#802__DriverPack.Embedded.1:LC.Embedded.1`

Once I have this information in my two-dimensional array I can create reports and manipulate the information to tell me exactly what version each of my servers is at.

Sweet! Step one to automating the update of our firmware complete! Next up figure out how to automate the deployment and installation of new firmware.
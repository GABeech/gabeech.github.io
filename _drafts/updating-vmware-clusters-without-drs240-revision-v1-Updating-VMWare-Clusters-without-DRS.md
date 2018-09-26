---
id: 242
title: Updating VMWare Clusters without DRS
date: 2014-03-05T01:55:09+00:00
author: George Beech
layout: revision
guid: http://brokenhaze.com/blog/2014/03/05/240-revision-v1/
permalink: /2014/03/05/240-revision-v1/
---
One of the pieces of the vSphere Enterprise license is DRS. Especially the ability to use DRS to one-click upgrade/update a cluster. If you don't know what DRS is, the short version is that it is a product you get with the Enterprise license which allows you to have vSphere move VMs around intelligently. One of the added bonuses you get is the ability to evacuate a VM. When you combine that with vSphere Update Manager you get a one-click and an hour later you're done upgrade of your cluster. 

Unfortunately, when that is the one feature you would actually use in the Enterprise edition it doesn't make financial sense to pay that premium. The question now is "What do you do to make your life easier than manually moving thing?"

The answer is you go and grab <a href="https://www.vmware.com/support/developer/PowerCLI/">Power CLI</a> and write a script! I've got one started -- Put github link here when done -- and I'll go through some of the details of it here.

First, what are the things that it can do?

<ul>
    <li> Migrate running VMs to the other hosts in the cluster</li>
    <li> Enter and Exit Maintenance mode</li>
    <li> Move the VMs from where they went, back to the host that was drained</li>
</ul>

Next, what still needs to be added?

<ul>
    <li> Intelligent migrations (it just blasts the vms around blindly now)</li>
    <li> automatically roll through the whole cluster</li>
    <li> Everything I haven't thought of ...</li>
</ul>

The most interesting function here is the <code>evac-host</code> function. This is actually the meat and bones of this script. 

[code autolink="false" lang="powershell"]
function evac-host()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string] $ClusterName,
        [Parameter(Mandatory=$true)]
        [string] $vHost
    )

    $AliveHosts = Get-VMHost -Location $ClusterName

    $toHosts = @()

    foreach ($h in $AliveHosts)
    {
        if($h.Name -ne $vHost)
        {

            $toHosts += $h.Name
        }
    }

    $svr = 0
    $vms = get-vm -Location $vHost | where {$_.PowerState -ne &quot;PoweredOff&quot;}
    $m_loc = @{}

    if ($vms.Count -gt 0)
    {

        foreach ($v in $vms)
        {
            Move-VM -vm $v.Name -Destination $toHosts[$svr]
            $m_loc.Add($v.Name, $toHosts[$svr])
    q
            if($svr -ne $toHosts.Length -1 )
            {
                $svr++
            }
            else
            {
                $svr = 0
            }

        }

        $m_loc.GetEnumerator() | Sort-Object Name | export-csv C:\Users\gbeech.STACKEXCHANGE\locations.csv
        $m_loc

    }
    else
    {
        write-host &quot;No Powered on VMs on the Host&quot;
    }
}
[/code]

The 10,000 foot view is that this function takes a Cluster Name (wild cards are acceptable), and a ESX host name as arguments. Then it goes through and moves every vm off the host. As it does this, it writes the names and locations they got sent to to a Hashtable, then writes those results out to a csv just in case. It also returns the hashtable so we can work with it later, avoiding having to read the csv back in.
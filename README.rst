Photoworld Graphing
===================

This repository contains what is required to setup the graphing backend of 
the Photoworld server. This is an optional extension that provides graphs 
analyzing data like logins, threads, length of a thread etc.

It currently closely follows the system that Etsy described in their blogpost 
based on StatsD and Graphite:

    http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/
    
The Photoworld server will send events to StatsD via a UDP socket, StatsD 
aggregates the data and passes it along to Graphite, which will draw the
graphs.


Installation
------------

Graphite is a bit of a monster of a system, and rather inflexible to install,
pulling an aweful lot of dependencies and refusing to install as a non-root
user in a virtualenv. Long story short, my natural impulse is to put it on a
separate system, so the main thing here is a Puppet recipe to configure a 
machine to run the daemons just as we need them.

The recipe takes inspiration from:
    https://gist.github.com/944849
    https://gist.github.com/1360928
    
and various other puppet/graphite repositories to be found on the web.
    
    
Specific steps:
---------------

- Install Puppet > 2.7.9

To use up a graphing server on EC2:
   
   - Install the Cloud Provisioner (http://docs.puppetlabs.com/guides/cloud_pack_getting_started.html):

       sudo gem install net-scp
       gem install fog -v 0.7.2
       gem install guid
       gem install puppet-module
       cd $(puppet --configprint confdir)/modules
       puppet-module install puppetlabs/cloud_provisioner
       export RUBYLIB=$(pwd)/cloud_provisioner/lib:$RUBYLIB
       puppet help node
       puppet help node_aws
       
   - Run ./setup_ec2.sh
   
The Puppet Cloud Provisioner is also helpful in installing puppet on a non-EC2
remote host.

To use a masterless Puppet to install the graphing server over SSH:

    - ./puppet_ssh_apply.sh USER@HOST
       
       
Debugging
---------

These commands are useful to see the packets received by statsd and sent to 
carbon:
       
    sudo ngrep -qd any stats tcp dst port 2003
    sudo ngrep -qd any . udp dst port 8125


TODO:
-----

Currently, statsite is used, a Python implementation of the original statsd.
I don't like how it puts the metric type in the bucket name (i.e. "kv"),
consider switching:

    https://github.com/Jonty/py-statsd
    https://github.com/etsy/statsd
    
The initial graphite-web user is not created correctly. We either need to ship
a Python script to e run by Puppet, or create a fixture file before running
syncdb.

Other links of interest:

https://github.com/obfuscurity/backstop
    Alternative to statsd

https://github.com/paperlesspost/graphiti
    Better UI for Graphite.

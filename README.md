#  Katello Formula
This is a [SaltStack](https://saltstack.com/) formula for maintaining a [Foreman](https://www.theforeman.org/) stack in the [Katello](https://www.theforeman.org/) scenario. This is still a work in progress and not all planned features have been implemented. With this formula, you can

 - Ensure your Foreman server is installed in the Katello scenario
 - Configure your foreman server using YAML
 - Deploy a new Foreman server
 - Add an existing minion that was not deployed using Katello to your foreman server

#  Quick start
Check out the quick-start [SLIK installer](https://github.com/jdshewey/slik-installer) which will take an unprovisioned server and install satstack and deploy a sample environment for demo purposes.

#  Usage instructions
To use this module, configure your katello.sls pillar (see this [tutorial](https://docs.saltstack.com/en/getstarted/config/pillar.html) or this [tutorial](https://docs.saltstack.com/en/latest/topics/tutorials/pillar.html)) using one of the examples located in the examples folder.

There are three examples, a demonstration of the bare minimum of options to generate a working install, which will not configure your server once deployed, a full install which exhaustively details every available option in Salt formula and a standard install, which configures some basic options for you. The SLIK installer will install the pillar file to /srv/pillar/ but if you have set a pillarenv, you will need to adjust accordingly. A few options of note:

Setting

    rc: true

will install the latest release candidate of The Foreman's Katello scenario while setting

    nightly: true

will install the nightly build. These are not recommended, however and are for development, testing and debugging.

##  Reinstalling and existing installs

To reinstall, either `rm /etc/slik/installed` or `yum -y remove katello` which will force a reinstall and cause the formula to reinstall all settings defined in your pillar.

For existing installations that you wish only to configure, simiply `touch /etc/slik/installed` and make sure Katello is properly installed and the formula will skip the installation step.

#  System Requirements

 - At least 8 GB of RAM is required for the installer to work properly which is an upstream dependancy on The Foreman installer which requires this amount of RAM to install/operate properly. 
 - Katello recommends at least 250 GB disk space - 50 for mongodb storage and 200 for RPM storage.

#  Bugs
Report bugs at https://github.com/jdshewey/salt-formula-katello/issues

#  Contributions
Contributions are extremely welcome! Please feel free to fork a copy of this formula and choose an issue or milestone to tackle. Once finished, and you are sure it is working, create a pull request for review, and I will do my best to reveiew and merge it as soon as possible.

#  Attribution
Created by James Shewey<br>
jdshewey.com<br>
jdshewey@gmail.com<br>

katello:
  server:
    admin_user: admin
    admin_pass: yfQk6pW51Peeu2byWtWh
    location: podunk
#    rc: true
#    nightly: true
    organizations:
      foobar:
#        subscription_manifest: manifest_6c20e080-2db6-455f-b340-56eaba3a7d16.zip
        products:
          Katello:
            repos:
              CentOS 7 Base:
                url: https://mirrors.kernel.org/centos/7/os/x86_64/
                gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
              CentOS 7 Extras:
                url: https://mirrors.kernel.org/centos/7/extras/x86_64/
                gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
              CentOS 7 Updates:
                url: https://mirrors.kernel.org/centos/7/updates/x86_64/
                gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
              CentOS 7 SLCo:
                url: https://mirrors.kernel.org/centos/7/sclo/x86_64/sclo/
                gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
              CentOS 7 SCLo - Red Hat:
                url: https://mirrors.kernel.org/centos/7/sclo/x86_64/rh/
                gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
              EPEL:
                url: https://mirrors.kernel.org/fedora-epel/7/x86_64/
                gpg_key: https://mirrors.kernel.org/fedora-epel/RPM-GPG-KEY-EPEL-7
              Foreman:
                url: https://yum.theforeman.org/releases/latest/el7/x86_64/
                gpg_key: https://yum.theforeman.org/RPM-GPG-KEY-foreman
              Foreman Plugins:
                url: https://yum.theforeman.org/plugins/latest/el7/x86_64/
                gpg_key: https://yum.theforeman.org/RPM-GPG-KEY-foreman
              Katello:
                url: https://fedorapeople.org/groups/katello/releases/yum/latest/katello/el7/x86_64/
                gpg_key: http://www.katello.org/gpg/RPM-GPG-KEY-katello-2015.gpg
              Katello Client:
                url: https://fedorapeople.org/groups/katello/releases/yum/latest/client/el7/x86_64/
                gpg_key: http://www.katello.org/gpg/RPM-GPG-KEY-katello-2015.gpg
              Candlepin:
                url: https://fedorapeople.org/groups/katello/releases/yum/latest/candlepin/el7/x86_64/
                gpg_key: http://www.katello.org/gpg/RPM-GPG-KEY-katello-2015.gpg
              Pulp:
                url: https://fedorapeople.org/groups/katello/releases/yum/latest/pulp/el7/x86_64/
                gpg_key: http://www.katello.org/gpg/RPM-GPG-KEY-katello-2015.gpg
              SaltStack:
                url: http://repo.saltstack.com/yum/redhat/7/x86_64/latest/
                gpg_key: https://repo.saltstack.com/yum/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub
              Puppet:
                url: https://yum.puppetlabs.com/el/7/PC1/x86_64/
                gpg_key: https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
          CentOS 7:
            repos:
              CentOS 7 Base:
                url: https://mirrors.kernel.org/centos/7/os/x86_64/
                gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
              CentOS 7 Extras:
                url: https://mirrors.kernel.org/centos/7/extras/x86_64/
                gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
              CentOS 7 Updates:
                url: https://mirrors.kernel.org/centos/7/updates/x86_64/
                gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7

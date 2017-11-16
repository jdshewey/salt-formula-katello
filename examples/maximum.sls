katello:
  server:
    admin_user: admin
    admin_pass: YEYorBtB6ZP1
    locations:
      - podunk
      - timbuktu
      - abu dhabi
    nightly: true
    organizations:
      foobar:
        subscription_manifest: manifest_6c20e080-2db6-455f-b340-56eaba3a7d16.zip
        products:
          Katello:
            sync_plan: daily
            CentOS 7 SLCo:
              url: https://mirrors.kernel.org/centos/7/sclo/x86_64/sclo/
              gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
            CentOS 7 SCLo - Red Hat:
              url: https://mirrors.kernel.org/centos/7/sclo/x86_64/rh/
              gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
            Foreman:
              url: https://yum.theforeman.org/releases/latest/el7/x86_64/
              gpg_key: https://yum.theforeman.org/RPM-GPG-KEY-foreman
            Foreman Plugins:
              url: https://yum.theforeman.org/plugins/latest/el7/x86_64/
              gpg_key: https://yum.theforeman.org/RPM-GPG-KEY-foreman
            Katello:
              url: https://fedorapeople.org/groups/katello/releases/yum/latest/katello/el7/x86_64/
              gpg_key: https://www.katello.org/gpg/RPM-GPG-KEY-katello-2015.gpg
            Katello Client:
              url: https://fedorapeople.org/groups/katello/releases/yum/latest/client/el7/x86_64/
              gpg_key: https://www.katello.org/gpg/RPM-GPG-KEY-katello-2015.gpg
            Candlepin:
              url: https://fedorapeople.org/groups/katello/releases/yum/latest/candlepin/el7/x86_64/
              gpg_key: https://www.katello.org/gpg/RPM-GPG-KEY-katello-2015.gpg
            Pulp:
              url: https://fedorapeople.org/groups/katello/releases/yum/latest/pulp/el7/x86_64/
              gpg_key: https://www.katello.org/gpg/RPM-GPG-KEY-katello-2015.gpg
            SaltStack:
              url: https://repo.saltstack.com/yum/redhat/7/x86_64/latest/
              gpg_key: https://repo.saltstack.com/yum/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub
            Puppet:
              url: https://yum.puppetlabs.com/el/7/PC1/x86_64/
              gpg_key: https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
          EPEL:
            sync_plan: weekly
            EPEL:
              url: https://mirrors.kernel.org/fedora-epel/7/x86_64/
              gpg_key: https://mirrors.kernel.org/fedora-epel/RPM-GPG-KEY-EPEL-7
          CentOS 7:
            sync_plan: hourly
            CentOS 7 Base:
              url: https://mirrors.kernel.org/centos/7/os/x86_64/
              gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
            CentOS 7 Extras:
              url: https://mirrors.kernel.org/centos/7/extras/x86_64/
              gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
            CentOS 7 Updates:
              url: https://mirrors.kernel.org/centos/7/updates/x86_64/
              gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7

####### Every Product automatically gets a matchomg Content View. Composite Views are made up
####### of two or more Content Views.

        composite_views:
          SLIK:
            - Katello
            - EPEL
            - CentOS 7
          CentOS 7 - EPEL:
            - CentOS 7
            - EPEL

####### Content Views are versioned and released/promoted to Lifecycle Environments.

        environments:
          - Dev
          - Test
          - Prod

####### Activation keys allow you to tie a host to a specific Lifecycle Environment and Content View
####### or Composite View.

        activation_keys
          SLIK:
            view: SLIK
            environment: Prod
            max_hosts: 10
          CentOS 7:
            view: CentOS 7 - EPEL
      barbaz:
        subscription_manifest: manifest_6c20e080-2db6-455f-b340-56eaba3a7d16.zip
        products:
          Fedora:
            sync_plan: manual
            CentOS 7 SLCo:
              url: https://mirrors.kernel.org/centos/7/sclo/x86_64/sclo/
              gpg_key: https://mirrors.kernel.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7

####### Content Views are versioned and released/promoted to Lifecycle Environments.

        environments:
          - Dev
          - Test
          - Prod

###### Activation keys allow you (optionally) to tie a host to a specific Lifecycle Environment and
###### Content View or Composite View.

       activation_keys:
         Fedora:
           view: Fedora

katello:
  server:
    admin_user: admin
    admin_pass: UtjDf83OJCVn
    locations:
      - podunk
#    rc: true
#    nightly: true
    organizations:
      foobar:
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
              gpg_key: https://raw.githubusercontent.com/Katello/katello.org/master/gpg/RPM-GPG-KEY-katello-2015.gpg
            Katello Client:
              url: https://fedorapeople.org/groups/katello/releases/yum/latest/client/el7/x86_64/
              gpg_key: https://raw.githubusercontent.com/Katello/katello.org/master/gpg/RPM-GPG-KEY-katello-2015.gpg
            Candlepin:
              url: https://fedorapeople.org/groups/katello/releases/yum/latest/candlepin/el7/x86_64/
              gpg_key: https://raw.githubusercontent.com/Katello/katello.org/master/gpg/RPM-GPG-KEY-katello-2015.gpg
            Pulp:
              url: https://fedorapeople.org/groups/katello/releases/yum/latest/pulp/el7/x86_64/
              gpg_key: https://raw.githubusercontent.com/Katello/katello.org/master/gpg/RPM-GPG-KEY-katello-2015.gpg
            SaltStack:
              url: https://repo.saltstack.com/yum/redhat/7/x86_64/latest/
              gpg_key: https://repo.saltstack.com/yum/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub
            Puppet:
              url: https://yum.puppetlabs.com/el/7/PC1/x86_64/
              gpg_key: https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
          EPEL:
            sync_plan: daily
            EPEL:
              url: https://mirrors.kernel.org/fedora-epel/7/x86_64/
              gpg_key: https://mirrors.kernel.org/fedora-epel/RPM-GPG-KEY-EPEL-7
          CentOS 7:
            sync_plan: daily
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
          - Dev:
            - Test:
              - Prod

###### Activation keys allow you to tie a host to a specific Lifecycle Environment and Content View
###### or Composite View.

        activation_keys:
          SLIK:
            view: SLIK
            environment: Prod
          CentOS 7:
            view: CentOS 7 - EPEL

### Compute resources are clouds or in-house clusters that you can deploy hosts to
### This works with Libvirt, Ovirt, EC2, Vmware, Openstack, Rackspace and GCE

    compute: 
      Google Cloud: 
        - provider: GCE
#      KVM:
#        - provider: Ovirt
#      Xen:
#        - provider: Libvirt
#      Amazon:
#        - provider: EC2
#        - user:
#        # this is actually your EC2 Key, but not sure if secret key or Access key 
#        - password:
#        - region: us-west-2
#      VMWare:
#        - provider: Vmware
#        # This can also be the actual service_account and service_account_password above if omitted 
#        - user: service_account
#        - password: k.djdnbglaf
#        - datacenter: HQ
#        - server: vcenter.example.com
#        # not required; sets a randomly generated password on the display connection
#        - set_console_password: True
#        # not required; Caches slow calls to VMWare to speed up page rendering
#        - caching_enabled: True
#      OpenStack:
#        - provider: Openstack
#      Rackspace:
#        - provider: Rackspace       
#
#    elif provider == 'Libvirt':
#        post_data['url'] = url
#        post_data['set_console_password'] = set_console_password
#        post_data['display_type'] = display_type
#
#    elif provider == 'Ovirt':
#        post_data['url'] = url
#        post_data['user'] = user
#        post_data['password'] = password
#        post_data['datacenter'] = datacenter
#
#    elif provider == 'Openstack':
#        post_data['url'] = url
#        post_data['user'] = user
#        post_data['password'] = password
#        post_data['tenant'] = tenant
#
#    elif provider == 'Rackspace':
#        post_data['url'] = url

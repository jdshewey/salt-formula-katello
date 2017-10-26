{%- from "katello/map.jinja" import server with context %}

katello_clean_yum:
  cmd.run:
    - name: yum -y clean all
    - unless:
      - test -e /etc/slik/installed
      - rpm -qa | egrep "^katello-3\."
katello_sources:
  file.managed:
    - name: /etc/yum.repos.d/katello-install.repo
    - source:  salt://katello/files/katello-install.repo
    - template: jinja
    - onchanges: 
      - cmd: katello_clean_yum
katello_server_pkgs:
  pkg.installed:
    - names: {{ server.pkgs }}
    - require:
      - file: katello_sources
      - cmd: katello_clean_yum
    - onchanges: 
      - cmd: katello_clean_yum
{%- if server.smart_proxies is defined %}
    - pkg: 
  {%- if 'abrt' in server.smart_proxies %}
      - rubygem-smart_proxy_abrt
  {%- endif %}
  {%- if 'ansible' in server.smart_proxies %}
      - rubygem-smart_proxy_ansible
  {%- endif %}
  {%- if 'dhcp_infoblox' in server.smart_proxies %}
      - rubygem-smart_proxy_dhcp_infoblox
  {%- endif %}
  {%- if 'dhcp_remote_isc' in server.smart_proxies %}
      - rubygem-smart_proxy_dhcp_remote_isc
  {%- endif %}
  {%- if 'discovery' in server.smart_proxies %}
      - rubygem-smart_proxy_discovery
  {%- endif %}
  {%- if 'discovery_image' in server.smart_proxies %}
      - rubygem-smart_proxy_discovery_image
  {%- endif %}
  {%- if 'dns_infoblox' in server.smart_proxies %}
      - rubygem-smart_proxy_dns_infoblox
  {%- endif %}
  {%- if 'dns_route53' in server.smart_proxies %}
      - rubygem-smart_proxy_dns_route53
  {%- endif %}
  {%- if 'dns_powerdns' in server.smart_proxies %}
      - rubygem-smart_proxy_dns_powerdns
  {%- endif %}
  {%- if 'monitoring' in server.smart_proxies %}
      - rubygem-smart_proxy_monitoring
  {%- endif %}
  {%- if 'omaha' in server.smart_proxies %}
      - rubygem-smart_proxy_omaha
  {%- endif %}
  {%- if 'openscap' in server.smart_proxies %}
      - rubygem-smart_proxy_openscap
  {%- endif %}
  {%- if 'remote_execution_ssh' in server.smart_proxies %}
      - rubygem-smart_proxy_remote_execution_ssh
  {%- endif %}
  {%- if 'dynflow' in server.smart_proxies %}
      - rubygem-smart_proxy_dynflow
  {%- endif %}
  {%- if 'pulp' in server.smart_proxies %}
      - rubygem-smart_proxy_pulp
  {%- endif %}
{%- endif %}
katello_answers:
  file.managed:
    - name: /etc/foreman-installer/scenarios.d/katello-answers.yaml
    - source:  salt://katello/files/katello-answers.yaml
    - template: jinja
    - onchanges: 
      - cmd: katello_clean_yum
#Fix for http://projects.theforeman.org/issues/20055
/opt/theforeman/tfm/root/usr/share/gems/gems/foreman_salt-8.0.2/db/seeds.d/75-salt_seeds.rb:
  file.managed:
    - source: salt://katello/files/75-salt_seeds.rb
    - require:
       - pkg: katello_server_pkgs    
katello_monkey_patch_for_bugs_21386_and_21401:
  cmd.run:
    - name: sed -i -e 's/puppet-server/puppetserver/g' /usr/share/foreman-installer/modules/puppet/manifests/server/install.pp
    - require:
      - file: /opt/theforeman/tfm/root/usr/share/gems/gems/foreman_salt-8.0.2/db/seeds.d/75-salt_seeds.rb
    - onchanges:
      - cmd: katello_clean_yum
katello_install:
  cmd.run:
{%- if grains.get('current_tty', None) == None %}
    - name: foreman-installer --scenario katello
{%- else %}
    - name: /bin/bash -c "foreman-installer --scenario katello &> >(tee {{ grains['current_tty'] }})"
{%- endif %}
    - require:
      - file: katello_answers
      - file: katello_sources
      - pkg: katello_server_pkgs
      - cmd: katello_monkey_patch_for_bugs_21386_and_21401
    - env:
      - LC_CTYPE: en_US.UTF-8
    - onchanges:
      - cmd: katello_clean_yum
katello_reset_pass:
  cmd.run:
    - name: curl -s -k -X PUT -u admin:$( foreman-rake permissions:reset | awk '{print $6}' ) -H "Content-Type:application/json" -H "Accept:application/json" -d '{"login":"admin","current_password":"{{ server.admin_pass }}"}' https://slik01.example.com/api/v2/users/3
    - require:
      - cmd: katello_install
    - onchanges:
      - cmd: katello_clean_yum
mkdir -p /etc/slik:
  cmd.run:
    - require:
      - cmd: katello_reset_pass 
    - onchanges:
      - cmd: katello_clean_yum
touch /etc/slik/installed:
  cmd.run:
    - require:
      - cmd: mkdir -p /etc/slik
    - onchanges:
      - cmd: katello_clean_yum
httpd:
  service.running:
    - enable: true
{%- if server.ldap is defined %}
katello_ldap:
  module:
    - run
    - name: katello.add_ldap_source
    - hostname: {{ grains['fqdn']  }}
    - username: {{ server.admin_user }}
    - password: {{ server.admin_pass }}
    - ldap_hostname: {{ server.ldap.source }}
    - port: 636
# When is http://projects.theforeman.org/issues/7016 gonna be patched? 
    - server_type: {{ server.get('server.ldap.type', 'free_ipa') }}
    - base_dn: {{ server.ldap.base_dn | urlencode() }}
{%- if server.ldap.type == undefined or server.ldap.type == 'free_ipa' %} 
    - kwargs: 
        ldap_user: {{ server.ldap.user }}
        ldap_password: {{ server.ldap.pass }}
        groups_base: {{ server.ldap.group_dn | urlencode() }}
        automagic_account_creation: {{ server.ldap.get('automagic_account_creation', 1) }} 
        usergroup_sync: {{ server.ldap.get('usergroup_sync', 1) }}
{%- endif %}
{%- endif %}

{%- from "katello/map.jinja" import server with context %}

########################################################
#
#    Helper Macro for Lifecycle Environment creation
#
########################################################

#Hack to create global variables to work around namespace/scope issues
{%- set global_org_name = [0] %}
{%- set global_last_env = [0] %}

{% macro environment_states(env) %}
{%- do salt.log.error(env) %}
  {%- if env is mapping %}
  #If this is one of the subsequent recursive calls of the macro
katello_create_env_{{ env[0].keys()[0] }}:
  module.run:
    - katello.create_environment:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ global_org_name[0] }}
      - environment_name: {{ env[0].keys()[0] }} 
    - onchanges:
      - cmd: katello_clean_yum
    {% set _ = global_last_env.pop() %}
    {% set _ = global_last_env.append(env[0].keys()[0]) %}
    {{ environment_states(env.values()[0]) }}
  {%- else %}
    {%- if env[0] is not string %}
    #If this is the first iteration of the macro
katello_create_env_{{ env[0].keys()[0] }}:
  module.run:
    - katello.create_environment:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ global_org_name[0] }}
      - environment_name: {{ env[0].keys()[0] }}
      - parent_environment: global_last_env[0] 
    - onchanges:
      - cmd: katello_clean_yum
      {% set _ = global_last_env.pop() %}
      {% set _ = global_last_env.append(env[0].keys()[0]) %}
      {{ environment_states(env[0].values()[0]) }}
    {%- else %}
    #if this is the final call of the macro
katello_create_env_{{ env[0] }}:
  module.run:
    - katello.create_environment:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ global_org_name[0] }}
      - environment_name: {{ env[0] }}
      {%- if global_last_env[0] != 0 %}
      #In case there is only 1 environment
      - parent_environment: global_last_env[0]
      {%- endif %}
    - onchanges:
      - cmd: katello_clean_yum
      #cleanup for possible future run
      {% set _ = global_last_env.pop() %}
      {% set _ = global_last_env.append(0) %}
    {%- endif %}
  {%- endif %}
{% endmacro %}

##############################
#
#    Katello installation
#
#############################

katello_clean_yum:
  cmd.run:
    - name: yum -y clean all || true
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
katello_clean_yum2:
  cmd.run:
    - name: yum -y clean metadata || true
    - onchanges: 
      - cmd: katello_clean_yum
    - require:
      - file: katello_sources
{%- if grains.get('current_tty', None) != None %}
katello_display_progress:
  cmd.run:
    - name: /bin/bash -c "yum -y install katello  &> >(tee {{ grains['current_tty'] }})"
    - require:
      - file: katello_sources
      - cmd: katello_clean_yum
    - onchanges:
      - cmd: katello_clean_yum
    - require_in:
      - pkg: katello_server_pkgs
    - env:
      - LC_CTYPE: en_US.UTF-8
{%- endif %}
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
    - env:
      - LC_CTYPE: en_US.UTF-8
    - onchanges:
      - cmd: katello_clean_yum
katello_reset_pass:
  cmd.run:
    - name: /bin/bash -c $'PASSWORD=$( foreman-rake permissions:reset 2> /dev/null | awk "{printf \$6}" ); curl -s -k -X PUT -u admin:$PASSWORD -H "Content-Type:application/json" -H "Accept:application/json" -d "{\\\"login\\\":\\\"admin\\\", \\\"current_password\\\":\\\"$PASSWORD\\\", \\\"password\\\":\\\"{{ server.admin_pass }}\\\"}" https://{{ grains['fqdn'] }}/api/v2/users/admin'
    - require:
      - cmd: katello_install
      - firewalld: public
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
katello_firewalld:
  firewalld.present:
    - name: public
    - services:
      - http
      - https
      - saltstack
      - ssh
      - dhcpv6-client

##################################################
#
#    Installation complete; begin configuraion
#
##################################################

{%- if server.ldap is defined %}
katello_ldap:
  module.run
    - name: katello.add_ldap_source
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - ldap_hostname: {{ server.ldap.source }}
      - port: 636
# When is http://projects.theforeman.org/issues/7016 gonna be patched?
      - server_type: {{ server.get('server.ldap.type', 'free_ipa') }}
      - base_dn: {{ server.ldap.base_dn | urlencode() }}
  {%- if server.ldap.type is not defined or server.ldap.type == 'free_ipa' %}
      - ldap_user: {{ server.ldap.user }}
      - ldap_password: {{ server.ldap.pass }}
      - groups_base: {{ server.ldap.group_dn | urlencode() }}
      - automagic_account_creation: {{ server.ldap.get('automagic_account_creation', 1) }}
      - usergroup_sync: {{ server.ldap.get('usergroup_sync', 1) }}
    - require:
      - firewalld: katello_firewalld
    - onchanges:
      - cmd: katello_clean_yum
  {%- endif %}
{%- endif %}

############################################################
#
#    Configure Content Views and Content View requisites
#
############################################################

{%- if server.organizations is defined %}
  {%- for org_name, org_data in server.organizations.iteritems() %}
katello_sync_plan_{{ org_name }}_hourly:
  module.run:
    - katello.create_sync_plan:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ org_name }}
      - frequency: hourly
    - require:
      - firewalld: katello_firewalld
    - onchanges:
      - cmd: katello_clean_yum
katello_sync_plan_{{ org_name }}_daily:
  module.run:
    - katello.create_sync_plan:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ org_name }}
      - frequency: daily
    - require:
      - firewalld: katello_firewalld
    - onchanges:
      - cmd: katello_clean_yum
katello_sync_plan_{{ org_name }}_weekly:
  module.run:
    - katello.create_sync_plan:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ org_name }}
      - frequency: weekly
    - require:
      - firewalld: katello_firewalld
    - onchanges:
      - cmd: katello_clean_yum
    {%- if org_data.products is defined %}
      {%- for product, repos in org_data.products.iteritems() %}
katello_product_{{ product }}:
  module.run:
    - katello.create_product:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ org_name }}
      - product_name: {{ product }}
        {%- if repos.sync_plan is defined %}
      - sync_plan: {{ repos.sync_plan }} 
    - require:
      - module: katello_sync_plan_{{ org_name }}_hourly
      - module: katello_sync_plan_{{ org_name }}_daily
      - module: katello_sync_plan_{{ org_name }}_weekly
        {%- else %}
    - require:
        {%- endif %}
      - firewalld: katello_firewalld
    - onchanges:
      - cmd: katello_clean_yum
        {%- for repo, info in repos.iteritems() %}
          {%- if repo != 'sync_plan' %}
katello_gpg_key_{{ product }}_{{ repo }}:
  module.run:
    - katello.load_gpg_key:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ org_name }}
      - key_url: {{ info.gpg_key }}
    - require:
      - firewalld: katello_firewalld
    - onchanges:
      - cmd: katello_clean_yum
katello_create_repo_{{ product }}_{{ repo }}:
  module.run:
    - katello.create_repo:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ org_name }}
      - repo_name: {{ repo }}
      - product_name: {{ product }}
      - gpg_key: {{ info.gpg_key }}
      - content_type: yum
      - repo_url: {{ info.url }}
    - require:
      - module: katello_product_{{ product }}
      - module: katello_gpg_key_{{ product }}_{{ repo }}
      - firewalld: katello_firewalld
    - require_in:
      - module: katello_create_view_{{ product }}
    - onchanges:
      - cmd: katello_clean_yum
          {%- endif %}
        {%- endfor %}
katello_create_view_{{ product }}:
  module.run:
    - katello.create_content_view:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ org_name }}
      - content_view_name: {{ product }}
      - content_repos: {{ repos }}
    - onchanges:
      - cmd: katello_clean_yum
katello_sync_product_{{ product }}:
  module.run:
    - katello.sync_product_repos:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ org_name }}
      - product_name: {{ product }}
    - require:
      - module: katello_create_view_{{ product }}
    - onchanges:
      - cmd: katello_clean_yum
      {%- endfor %}
    {%- endif %}

##################################
#
#    Configure Composite Views
#
##################################

    {% if org_data.composite_views is defined %}
      {%- for view_name, child_views in org_data.composite_views.iteritems() %}
katello_create_composite_view_{{ view_name }}:
  module.run:
    - katello.create_composite_view:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ org_name }}
      - composite_view_name: {{ view_name }}
      - content_views: {{ child_views }}
    - onchanges:
      - cmd: katello_clean_yum
    - require:
        {%- for content_view in child_views %}
      - module: katello_sync_product_{{ content_view }}
        {%- endfor %}
      {%- endfor %}
    {%- endif %}

#########################################
#
#    Configure Lifecycle Environments
#
#########################################

    {% if org_data.environments is defined %}
      {% set _ = global_org_name.pop() %}
      {% set _ = global_org_name.append(org_name) %}
      {{ environment_states(org_data.environments) }}
    {%- endif %}
  {%- endfor %}
{%- endif %}



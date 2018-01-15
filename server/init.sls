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
  {%- if env[0] is not string %}
  #If this is not the final iteration of the macro
katello_create_env_{{ env[0].keys()[0] }}:
  module.run:
    - katello.create_environment:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ global_org_name[0] }}
      - environment_name: {{ env[0].keys()[0] }}
    {%- if global_last_env[0] != 0 %}
    #If this is the first iteration of the macro
      - parent_environment: {{ global_last_env[0] }}
    - require:
      - module: katello_create_env_{{ global_last_env[0] }}
    {%- endif %}
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
      - parent_environment: {{ global_last_env[0] }}
    - require:
      - module: katello_create_env_{{ global_last_env[0] }}
    {%- endif %}
    - onchanges:
      - cmd: katello_clean_yum
      #cleanup for possible future run
      {% set _ = global_last_env.pop() %}
      {% set _ = global_last_env.append(0) %}
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

{%- if server.nightly is not defined and server.rc is not defined %}
#Fix for http://projects.theforeman.org/issues/20055
/opt/theforeman/tfm/root/usr/share/gems/gems/foreman_salt-8.0.2/db/seeds.d/75-salt_seeds.rb:
  file.managed:
    - source: salt://katello/files/monkey-patching/75-salt_seeds.rb
    - require:
       - pkg: katello_server_pkgs 
    - onchanges: 
      - cmd: katello_clean_yum
{%- endif %}

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

{%- if server.nightly is not defined and server.rc is not defined %}
#Fix for http://projects.theforeman.org/issues/22206
/opt/theforeman/tfm/root/usr/share/gems/gems/katello-3.5.0.1/app/models/katello/repository.rb:
  file.managed:
    - source: salt://katello/files/monkey-patching/repository.rb
    - require:
       - pkg: katello_server_pkgs 
    - onchanges: 
      - cmd: katello_clean_yum
/opt/theforeman/tfm/root/usr/share/gems/gems/katello-3.5.0.1/app/lib/actions/katello/repository/sync_hook.rb:
  file.managed:
    - source: salt://katello/files/monkey-patching/sync_hook.rb
    - require:
       - pkg: katello_server_pkgs 
    - onchanges: 
      - cmd: katello_clean_yum
/opt/theforeman/tfm/root/usr/share/gems/gems/katello-3.5.0.1/app/lib/actions/katello/repository/sync.rb:
  file.managed:
    - source: salt://katello/files/monkey-patching/sync.rb
    - require:
       - pkg: katello_server_pkgs 
    - onchanges: 
      - cmd: katello_clean_yum
#Fix for http://projects.theforeman.org/issues/22070
/opt/theforeman/tfm/root/usr/share/gems/gems/foreman_hooks-0.3.14/lib/foreman_hooks/util.rb:
  file.managed:
    - source: salt://katello/files/monkey-patching/sync.rb
    - require:
       - pkg: katello_server_pkgs 
    - onchanges: 
      - cmd: katello_clean_yum
{%- endif %}

katello_create_bootstraping:
  file.directory:
    - name: /var/www/html/pub/bootstrap
    - user: apache
    - group: apache
    - dir_mode: 755
    - require:
      - cmd: katello_install
    - onchanges:
      - cmd: katello_clean_yum
katello_create_bootstraping_7:
  file.directory:
    - name: /var/www/html/pub/bootstrap/el7
    - user: apache
    - group: apache
    - dir_mode: 755
    - require:
      - cmd: katello_install
      - file: katello_create_bootstraping
    - onchanges:
      - cmd: katello_clean_yum
katello_create_bootstraping_6:
  file.directory:
    - name: /var/www/html/pub/bootstrap/el6
    - user: apache
    - group: apache
    - dir_mode: 755
    - require:
      - cmd: katello_install
      - file: katello_create_bootstraping
    - onchanges:
      - cmd: katello_clean_yum
katello_prep_client_attachments_7_sub_mgr:
  cmd.run:
    - name: curl -s https://mirrors.kernel.org/centos/7/updates/x86_64/Packages/$( curl -s https://mirrors.kernel.org/centos/7/updates/x86_64/Packages/ | grep subscription-manager-[1-9] | awk -F\" '{print $2}' ) -O
    - cwd: /var/www/html/pub/bootstrap/el7
    - require:
      - cmd: katello_install
      - file: katello_create_bootstraping_7
    - onchanges:
      - cmd: katello_clean_yum
katello_prep_client_attachments_7_python-rhsm:
  cmd.run:
    - name: curl -s https://mirrors.kernel.org/centos/7/updates/x86_64/Packages/$( curl -s https://mirrors.kernel.org/centos/7/updates/x86_64/Packages/ | grep python-rhsm-[1-9] | awk -F\" '{print $2}' ) -O
    - cwd: /var/www/html/pub/bootstrap/el7
    - require:
      - cmd: katello_install
      - file: katello_create_bootstraping_7
    - onchanges:
      - cmd: katello_clean_yum
katello_prep_client_attachments_7_python-rhsm-certificates:
  cmd.run:
    - name: curl -s https://mirrors.kernel.org/centos/7/updates/x86_64/Packages/$( curl -s https://mirrors.kernel.org/centos/7/updates/x86_64/Packages/ | grep python-rhsm-certificates-[1-9] | awk -F\" '{print $2}' ) -O
    - cwd: /var/www/html/pub/bootstrap/el7
    - require:
      - cmd: katello_install
      - file: katello_create_bootstraping_7
    - onchanges:
      - cmd: katello_clean_yum
katello_symlink_consumer_el7:
  file.symlink:
    - name: /var/www/html/pub/bootstrap/el7/katello-ca-consumer-latest.noarch.rpm
    - target: /var/www/html/pub/katello-ca-consumer-latest.noarch.rpm 
    - require:
      - cmd: katello_install
      - file: katello_create_bootstraping_7
    - onchanges:
      - cmd: katello_clean_yum
katello_createrepo_7:
  cmd.run:
    - name: createrepo /var/www/html/pub/bootstrap/el7
    - require:
      - cmd: katello_install
      - cmd: katello_prep_client_attachments_7_python-rhsm-certificates
      - cmd: katello_prep_client_attachments_7_python-rhsm
      - cmd: katello_prep_client_attachments_7_sub_mgr
      - file: katello_symlink_consumer_el7
    - onchanges:
      - cmd: katello_clean_yum

katello_prep_client_attachments_6:
  cmd.run:
#pinning to such a specific version is suboptimal. Such is life.
    - name: curl -s https://copr-be.cloud.fedoraproject.org/results/dgoodwin/subscription-manager/epel-6-x86_64/00273890-subscription-manager/subscription-manager-1.17.6-1.el6.x86_64.rpm -O
    - cwd: /var/www/html/pub/bootstrap/el6
    - require:
      - cmd: katello_install
    - onchanges:
      - cmd: katello_clean_yum
katello_symlink_consumer_el6:
  file.symlink:
    - name: /var/www/html/pub/bootstrap/el6/katello-ca-consumer-latest.noarch.rpm
    - target: /var/www/html/pub/katello-ca-consumer-latest.noarch.rpm 
    - require:
      - cmd: katello_install
      - file: katello_create_bootstraping_6
    - onchanges:
      - cmd: katello_clean_yum
katello_createrepo_6:
  cmd.run:
    - name: createrepo /var/www/html/pub/bootstrap/el6
    - require:
      - cmd: katello_install
      - cmd: katello_prep_client_attachments_6
      - file: katello_symlink_consumer_el6
    - onchanges:
      - cmd: katello_clean_yum

install_complete:
  file.directory:
    - name: /etc/slik
    - require:
      - cmd: katello_createrepo_6
      - cmd: katello_createrepo_7 
    - onchanges:
      - cmd: katello_clean_yum
touch /etc/slik/installed:
  cmd.run:
    - require:
      - file: install_complete
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
  module.run:
    - katello.add_ldap_source:
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
  {%- endif %}
    - require:
      - firewalld: katello_firewalld
    - onchanges:
      - cmd: katello_clean_yum
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
        {%- if org_data.environments is defined %}
    - require_in:
          {%- if org_data.environments[0] is not string %}
      - module: katello_create_env_{{ org_data.environments[0].keys()[0] }}
          {%- else %}
      - module: katello_create_env_{{ org_data.environments[0] }}
          {%- endif %}
        {%- endif %}
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

    {% if org_data.activation_keys is defined %}
      {%- for key_name, associations in org_data.activation_keys.iteritems() %}
katello_create_activation_key_{{ key_name }}:
  module.run:
    - katello.create_activation_key:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
      - password: {{ server.admin_pass }}
      - organization: {{ org_name }}
      - name: {{ key_name }}
        {% if associations.view is defined %}
      - content_view: {{ associations.view }}
        {%- endif %}
        {% if associations.environment is defined %}
      - environment: {{ associations.environment }}
    - require:
      - module: katello_create_env_{{ associations.environment }} 
        {%- endif %}
#    - onchanges:
#      - cmd: katello_clean_yum
      {%- endfor %}
    {%- endif %}
  {%- endfor %}
{%- endif %}



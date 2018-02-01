{%- from "katello/map.jinja" import client with context %}
katello_setup_bootstrap_repo:
  pkgrepo.managed:
    - name: bootstrapping
    - humanname: Katello bootstrapping repo
    - baseurl: https://{{ grains['master'] }}/pub/bootstrap/el{{ grains['fqdn'] }}/
    - gpgcheck: 0
    - sslverify: 0
    - onlyif:
      - test -z "$( rpm -qa | grep 'katello-ca-consumer-')"
katello_consumer_install:
  pkg.installed:
    - name: katello-ca-consumer-{{ grains.master }}
    - require:
      - pkgrepo: katello_setup_bootstrap_repo
    - onchanges:
      - pkgrepo: katello_setup_bootstrap_repo
katello_clean_subscriptions:
  cmd.run:
    - name: subscription-manager clean
    - require:
      - pkg: katello_consumer_install
    - onchanges:
      - pkg: katello_consumer_install
katello_clean_subscriptions_more_cleaner:
  cmd.run:
    - name: rm -rf /etc/yum.repos.d/*
    - require:
      - pkg: katello_consumer_install
    - onchanges:
      - pkg: katello_consumer_install
{%- for company_name, activation_keys in client.items() %}
katello_activate_client_{{ company_name }}:
  cmd.run: 
  {%- if grains['master'] == grains['fqdn'] %}
    - name: subscription-manager register --activationkey="{{ activation_keys.server_activation_key.keys()[0] }}" --org "{{ company_name }}" --force
  {%- elif activation_keys.activation_key is defined %}
    - name: subscription-manager register --activationkey="{{ activation_keys.activation_key.keys()[0] }}" --org "{{ company_name }}" --force
  {%- else %}
    - name: subscription-manager register --activationkey="{{ activation_keys.default_activation_key.keys()[0] }}" --org "{{ company_name }}" --force
  {%- endif %}
    - require:
      - pkg: katello_consumer_install
      - cmd: katello_clean_subscriptions
      - cmd: katello_clean_subscriptions_more_cleaner
    - onchanges:
      - pkg: katello_consumer_install
    - require_in:
      - pkg: katello_agent_install
katello_agent_install:
  pkg.latest:
    - name: katello-agent 
{%- endfor %}
{%- if grains['osmajorrelease'] != 6 %}
katello_update_host_info:
  cmd.run:
    - name: katello-tracer-upload
    - require:
      - pkg: katello_agent_install
{%- endif %}
katello_gofer:
  service.running:
    - name: goferd
    - enable: True
    - require:
      - pkg: katello_agent_install

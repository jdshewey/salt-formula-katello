{%- from "katello/map.jinja" import client with context %}
katello_consumer_install:
  pkg.installed:
    - sources:
#Located at /var/www/html/pub/
      - katello-ca-consumer-{{ grains.master }}: https://{{ grains.master }}/pub/katello-ca-consumer-latest.noarch.rpm
      - subscription-manager: https://{{ grains.master }}/pub/subscription-manager.el7.centos.x86_64.rpm
    - allow_updates: True
katello_clean_subscriptions:
  cmd.run:
    - name: subscription-manager clean
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
{%- endfor %}
    - require:
      - pkg: katello_consumer_install
      - cmd: katello_clean_subscriptions
    - onchanges:
      - pkg: katello_consumer_install
katello_agent_install:
  pkg.latest:
    - name: katello-agent 
    - require:
      - pkg: katello_consumer_install
      - cmd: katello_clean_subscriptions
      - cmd: katello_activate_client
    - onchanges:
      - pkg: katello_consumer_install
katello_update_host_info:
  cmd.run:
    - name: katello-tracer-upload
    - require:
      - pkg: katello_agent_install
katello_gofer:
  service.running:
    - name: goferd
    - enable: True
    - require:
      - pkg: katello_agent_install

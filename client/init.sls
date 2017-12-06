{%- from "katello/map.jinja" import client with context %}
katello_consumer_install:
  pkg.installed:
    - sources:
#Located at /var/www/html/pub/
      - katello-ca-consumer-slik01.example.com: https://{{ grains.master }}/pub/katello-ca-consumer-latest.noarch.rpm
      - subscription-manager: https://{{ grains.master }}/pub/subscription-manager.el7.centos.x86_64.rpm
    - allow_updates: True
katello_activate_client:
  cmd.run: 
{%- for company_name, activation_keys in client.items() %} #There should only be one key per file
  {%- if client.activation_key is defined %}
    - name: subscription-manager register --activationkey="{{ client.items()[0][1].activation_key.items()[0][0] }}" --org "{{ company_name }}" --force
  {%- elif grains['master'] == grains['fqdn'] %}
    - name: subscription-manager register --activationkey="{{ client.items()[0][1].server_activation_key.items()[0][0] }}" --org "{{ client.items()[0][0] }}" --force
  {%- else %}
    - name: subscription-manager register --activationkey="{{ cleint.items()[0][1].default_activation_key.items()[0][0] }}" --org "{{ company_name }}" --force
  {%- endif %}
{%- endfor %}
    - require:
      - pkg: katello_consumer_install
    - onchanges:
      - pkg: katello_consumer_install
katello_update_host_info:
  cmd.run:
    - name: katello-tracer-upload

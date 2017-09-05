{%- if pillar.katello is defined %}
include:
{%- if pillar.katello.client is defined %}
- katello.client
{%- endif %}
{%- if pillar.katello.server is defined %}
- katello.server
{%- endif %}
{%- endif %}

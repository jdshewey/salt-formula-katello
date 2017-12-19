{%- set server = salt['grains.filter_by']( {}, merge=salt['pillar.get']('katello:server')) %}
katello_driver:
  module.run:
    - katello.create_composite_view:
      - hostname: {{ grains['fqdn'] }}
      - username: {{ server.admin_user }}
{%- do salt.log.error(grains['fqdn']) %}
      - password: {{ server.admin_pass }}
      - organization: "foobar"
      - composite_view_name: "SLIK3"
      - content_views: {{ server.organizations.foobar.composite_views.SLIK }}

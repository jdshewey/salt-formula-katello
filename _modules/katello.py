# -*- coding: utf-8 -*-
'''
An execution module which can manipulate Katello via REST API
    :maturity:      develop
    :platform:      foreman 1.13.4 / 3.2.2
'''

# Import python libs
from __future__ import absolute_import
import json
import urllib
import os
import time
#import logging as logger

# Import third party libs
try:
    import requests
    import requests.exceptions
    from requests.auth import HTTPBasicAuth
    HAS_LIBS = True
except ImportError:
    HAS_LIBS = False

# Import salt libs
import salt.utils
import salt.output
import salt.exceptions

'''
Todo:
 * Add ability to delete OS
 * Revise OS adds
 * Update media location and org IDs
'''


# Define the module's virtual name
__virtualname__ = 'katello'


def __virtual__():
    '''
    Only return if requests is installed
    '''
    if HAS_LIBS:
        return __virtualname__
    return (False, 'The katello execution module cannot be loaded: '
            'python requests library not available.')

def _load_connection_error(hostname, error):
    '''
    Format and Return a connection error
    '''

    ret = {'code': None, 'content':
           'Unable to connect to the foreman: {host}\n{error}'.format(host=hostname,
                                                                      error=error)}

    return ret

def _load_response(response):
    '''
    Load the response from json data, return the dictionary or raw text
    '''

    try:
        data = json.loads(response.text)
    except ValueError:
        data = response.text

    ret = {'code': response.status_code, 'content': data}

    return ret

def check_settings(hostname, username, password,
                   uri):
    '''
    GET list of objects from URI and return this hash
    '''

    try:
        response = requests.get('https://' + hostname + uri, auth=HTTPBasicAuth(username, password))
    except requests.exceptions.ConnectionError as error:
        return _load_connection_error(hostname, error)

    data = _load_response(response)

    if data['code'] == 200:
        return data['content']['results']
    else:
        raise ValueError(str(data['code']) + ' querying ' + 'https://' + hostname + uri)

def add_media(hostname, username, password, name,
              os_family,
              path,
              location,
              organization
             ):
    '''
    A function to add a medium to foreman
    See https://theforeman.org/api/1.14/apidoc/v2/media/create.html for parameter definitions

    This function will not clobber existing values as Katello has several default media we do not
    want to remove.
    '''

    if location != None:
        locations = check_settings(hostname, username, password, "/api/locations")
        for facility in locations:
            if facility['name'] == location:
                location_id = facility['id']
        if 'location_id' not in locals():
            raise ValueError("Unable to find location - check spelling")

    else:
        location_id = None

    if organization != None:
        organizations = check_settings(hostname, username, password, "/katello/api/organizations")
        for group in organizations:
            if group['name'] == organization:
                organization_id = group['id']
        if 'organization_id' not in locals():
            raise ValueError("Error: Unable to find organization - check spelling")
    else:
        organization_id = None

    media = check_settings(hostname, username, password, '/api/media')
    for disk in media:
        if disk['name'] == name:
            if disk['os_family'] != os_family or disk['path'] != path:
                response = requests.delete('https://' + hostname + '/api/media/%s' % disk['id'],
                                           auth=HTTPBasicAuth(username, password))
                data = _load_response(response)

                if data['code'] != 200:
                    raise ValueError(str(data['code']) + ": " + json.dumps(data['content']))
            else:
                spoof = {'code': 200, 'content': disk}
                return spoof

    response = requests.post('https://' + hostname + '/api/media/',
                             data=json.dumps({'name': name, 'os_family': os_family, 'path': path,
                                              'locations': [{'id': location_id}], 'organizations':
                                              [{'id': organization_id}]}),
                             headers={'Content-Type': 'application/json'},
                             auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 201:
        return data

    else:
        raise ValueError(str(data['code']) + ": " + json.dumps(data['content']))

def del_media(hostname, username, password, name):
    '''
    A function to remove medium from foreman.

    Input parameter: Name of media (which is converted to ID)

    This allows you to remove existing values in Katello including default media.
    '''

    media = check_settings(hostname, username, password, '/api/media')
    for disk in media:
        if disk['name'] == name:
            response = requests.delete('https://' + hostname + '/api/media/%s' % disk['id'],
                                       auth=HTTPBasicAuth(username, password))
            data = _load_response(response)

            if data['code'] == 200:
                return data['content']['results']

            else:
                raise ValueError(str(data['code']) + ": " + json.dumps(data['content']))
    if data is None:
        return "Deleted"

def add_os(hostname, username, password, name,
           major_ver,
           minor_ver,
           os_family,
           media_path,
           location,
           organization
          ):
    '''
    This function creates an Operating System entry in Foreman. I am choosing to make this function
    dependant on add_media. I can't see a scenario in which you would not have a 1-to-1 relationship
    between OS and media (perhaps because OSs can't be bound to location?), but if someone can
    provide a use case, then shoot me an E-mail at jdshewey [at] gmail [dot] com I'll consider
    adding it or just do a pull request and fix it yourself. Similarly, there are many other
    parameters this could take, but I'm not sure why they are needed. For now I'm just trying to get
    a minimum baseline up and working. We can get fancier once we can do an end-to-end deployment,
    but let's just get SOMETHING working for now.

    TODO:
        * Lookup x86_64 first in case user acccidentally deleted and re-adds it
    '''

    oses = check_settings(hostname, username, password, '/api/operatingsystems')
    for op_sys in oses:
        if op_sys['name'] == name:
            if (op_sys['major'] != major_ver or op_sys['minor'] != minor_ver 
                or op_sys['family'] != 'os_family'):

                response = requests.delete('https://' + hostname + '/api/operatingsystems/%s' %
                                           op_sys['id'], auth=HTTPBasicAuth(username, password))
                data = _load_response(response)

                if data['code'] != 200:
                    raise ValueError(str(data['code']) + ": " + json.dumps(data['content']))
        if data is None:
            spoof = {'code': 200, 'content': op_sys}
            return spoof


    data = add_media(hostname, username, password,
                     name, os_family, media_path, location, organization)
    if data['code'] != 201 and data['code'] != 200:
        raise ValueError('Problem adding/updating media: ' +
                         str(data['code']) + ": " + json.dumps(data['content']))

    response = requests.post('https://' + hostname + '/api/operatingsystems/',
                             data=json.dumps({'name': name, 'family': os_family, 'major': major_ver,
                                              'minor': minor_ver, 'password_hash': 'SHA512',
                                              'architectures': [{'id':1}], 'mediums':
                                              [{'id':data['content']['id']}]}),
                             headers={'Content-Type': 'application/json'},
                             auth=HTTPBasicAuth(username, password))
                             #Seriously, if you are mad about the arch and hash, stop using old,
                             #insecure and outdated crap.

    data = _load_response(response)

    if data['code'] == 201:
        return data

    else:
        raise ValueError(str(data['code']) + ": " + json.dumps(data['content']))

def add_ldap_source(hostname, username, password,
                    ldap_hostname,
                    port,
                    server_type,
                    base_dn,
                    *args, **kwargs):

    ldap_user                   = kwargs.get('ldap_user', None)
    ldap_password               = kwargs.get('ldap_password', None)
    automagic_account_creation  = kwargs.get('automagic_account_creation', 0)
    usergroup_sync              = kwargs.get('usergroup_sync', 0)
    groups_base                 = kwargs.get('groups_base', None)
    ldap_filter                 = kwargs.get('ldap_filter', None)
    if server_type == 'free_ipa':
        attr_map_login          = 'uid'
        attr_map_given_name     = 'givenName'
        attr_map_family_name    = 'sn'
        attr_map_email          = 'mail'
        attr_map_mugshot        = 'photo'
    else:
        attr_map_login          = kwargs.get('attr_map_login', None)
        attr_map_given_name     = kwargs.get('attr_map_given_name', None)
        attr_map_family_name    = kwargs.get('attr_map_family_name', None)
        attr_map_email          = kwargs.get('attr_map_email', None)
        attr_map_mugshot        = kwargs.get('attr_map_mugshot', None)
    tls                         = 1 # Dude, seriously, don't use unencrypted connections

    '''
    TODO:
        * Verify password and update it if changed
    '''

#    ldap_sources = check_settings(hostname, username, password, '/api/auth_source_ldaps')
#    for source in ldap_sources:
#        if source['name'] == ldap_hostname:
            # Overwrite/update existing LDAP settings
#            if (source['account'] != ldap_user or source['port'] != port or
#                source['host'] != ldap_hostname or source['server_type'] != server_type or
#                source['onthefly_register'] != automagic_account_creation or
#                source['usergroup_sync'] != usergroup_sync or
#                source['groups_base'] != groups_base or source['ldap_filter'] != ldap_filter or
#                source['attr_login'] != attr_map_login or
#                source['attr_firstname'] != attr_map_given_name or
#                source['attr_lastname'] != attr_map_family_name or
#                source['attr_mail'] != attr_map_email or
#                source['attr_photo'] != attr_map_mugshot or
#                source['base_dn'] !=  urllib.unquote(base_dn)):
#                response = requests.delete('https://' + hostname + '/api/auth_source_ldaps/%s' %
#                                           source['id'], auth=HTTPBasicAuth(username, password))
#                data = _load_response(response)
#
#                if data['code'] != 200:
#                    raise ValueError(str(data['code']) + ": " + json.dumps(data['content']))
#            elif 'data' not in locals():
#                spoof = {'code': 200, 'content': source}
#                return spoof
#
#        else:
    response = requests.post('https://' + hostname + '/api/auth_source_ldaps',
                             data=json.dumps({'name': ldap_hostname,
                                              'host': ldap_hostname,
                                              'port': port, 'account': ldap_user,
                                              'account_password': ldap_password,
                                              'server_type': server_type,
                                              'base_dn': urllib.unquote(base_dn),
                                              'attr_login': attr_map_login,
                                              'attr_firstname': attr_map_given_name,
                                              'attr_lastname': attr_map_family_name,
                                              'attr_mail': attr_map_email,
                                              'attr_photo': attr_map_mugshot,
                                              'onthefly_register': automagic_account_creation,
                                              'usergroup_sync': usergroup_sync,
                                              'tls': tls,
                                              'groups_base': urllib.unquote(groups_base),
                                              'ldap_filter': ldap_filter}),
                             headers={'Content-Type': 'application/json'},
                             auth=HTTPBasicAuth(username, password))
                              #Seriously, if you are mad about the arch and hash, stop using
                              #old, insecure and outdated crap.

    data = _load_response(response)

    if data['code'] == 201:
        return data
    elif data['code'] == 422:
        return 'This LDAP source already exists'
    else:
        raise ValueError(str(data['code']) + ": " + json.dumps(data['content']))

def upload_rh_subscriptions(hostname, username, password, organization, path):
    '''
    See https://theforeman.org/plugins/katello/nightly/user_guide/red_hat_content/index.html
    TODO:
        * See if we can auto-detect path and filename
        * Block and wait and confirm successful upload instead of just fire it off and hope for the
          best
    '''

    organizations = check_settings(hostname, username, password, "/katello/api/organizations")
    for group in organizations:
        if group['name'] == organization:
            organization_id = group['id']
    if 'organization_id' not in locals():
        raise ValueError("Unable to find organization - check spelling")

    response = requests.post('https://' + hostname + '/katello/api/organizations/' +
                             str(organization_id) + '/subscriptions/upload',
                             files={'content': open(path, 'rb')},
                             auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 202:
        return data

    else:
        raise ValueError(str(data['code']) + ": " + json.dumps(data['content']))

def load_gpg_key(hostname, username, password, organization, key_url):
    #allow_insecure  = kwargs.get('allow_insecure', 0)

    organizations = check_settings(hostname, username, password, "/katello/api/organizations")
    for group in organizations:
        if group['name'] == organization:
            organization_id = group['id']
        else:
            raise ValueError("Unable to find organization - check spelling")

    #connection = requests.Session()

    #if allow_insecure:
    #    class HostNameIgnoringAdapter(HTTPAdapter):
    #        def init_poolmanager(self, connections, maxsize, block=False):
    #            self.poolmanager = PoolManager(num_pools=connections,
    #                                       maxsize=maxsize,
    #                                       block=block,
    #                                       assert_hostname=False)
    #    connection.mount('https://', HostNameIgnoringAdapter())

    if key_url.startswith("http"):
        response = requests.get(key_url)
        data = _load_response(response)

        if data['code'] != 200:
            raise ValueError(str(data['code']) + ": " + json.dumps(data['content']))

    else:
        try:
            with open(key_url, 'r') as f:
                data = { 'content':f.read() }
            f.closed
        except IOError as error:
            raise ValueError("Could not open file: " + str(error))

    response = requests.post('https://' + hostname +
                             '/katello/api/gpg_keys',
                             data=json.dumps({'organization_id': organization_id, 'name':
                                              os.path.basename(key_url),
                                              'content': data['content']}),
                             headers={'Content-Type': 'application/json'},
                             auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 200:
        return data

    elif data['code'] == 422:
        return 'A GPG key with this name already exists'

    else:
        raise ValueError(str(data['code']) + " - " + json.dumps(data['content']))

def create_sync_plan(hostname, username, password, organization, frequency):
    '''
    TODO:
        Add editing for GPG Key
    '''
    organizations = check_settings(hostname, username, password, "/katello/api/organizations")
    for group in organizations:
        if group['name'] == organization:
            organization_id = group['id']
    if 'organization_id' not in locals():
        raise ValueError("Unable to find organization - check spelling")

    response = requests.post('https://' + hostname + '/katello/api/organizations/' +
                             str(organization_id) + '/sync_plans',
                             data=json.dumps({'organization_id': organization_id, 'name':
                                              frequency, 'interval': frequency, 'description':
                                              frequency, 'enabled': 1, 'sync_date':
                                              time.strftime("%Y-%m-%d %H:%M:%S UTC")}),
                             headers={'Content-Type': 'application/json'},
                             auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 200:
        return data
    elif data['code'] == 422:
        return 'A ' + frequency + ' sync plan already exists'
    else:
        raise ValueError(str(data['code']) + " - " + json.dumps(data['content']))

def create_product(hostname, username, password, organization, product_name, *args, **kwargs):

    sync_plan = kwargs.get('sync_plan', None)

    organizations = check_settings(hostname, username, password, "/katello/api/organizations")
    for group in organizations:
        if group['name'] == organization:
            organization_id = group['id']
    if 'organization_id' not in locals():
        raise ValueError("Unable to find organization - check spelling")

    if sync_plan is None:
        response = requests.post('https://' + hostname +
                                 '/katello/api/products',
                                 data=json.dumps({'organization_id': organization_id, 'name':
                                                  product_name, 'description': product_name,
                                                  'label': product_name.replace(" ", "_")}),
                                 headers={'Content-Type': 'application/json'},
                                 auth=HTTPBasicAuth(username, password))
    else:
        sync_plans = check_settings(hostname, username, password,
                                    "/katello/api/sync_plans?organization_id="
                                    + str(organization_id))
        for plan in sync_plans:
            if plan['interval'] == sync_plan:
                sync_plan_id = plan['id']

        response = requests.post('https://' + hostname +
                                 '/katello/api/products',
                                 data=json.dumps({'organization_id': organization_id, 'name':
                                                  product_name, 'description': product_name,
                                                  'label': product_name.replace(" ", "_"),
                                                  'sync_plan_id': sync_plan_id}),
                                 headers={'Content-Type': 'application/json'},
                                 auth=HTTPBasicAuth(username, password))


    data = _load_response(response)

    if data['code'] == 200:
        return data
    elif data['code'] == 422:
        return 'A product with this name already exists'
    else:
        raise ValueError(str(data['code']) + " - " + json.dumps(data['content']))

def create_repo(hostname, username, password,
                organization,
                repo_name,
                product_name,
                gpg_key,
                content_type,
                *args, **kwargs):
    repo_url        = kwargs.get('repo_url', None)
    unprotected     = kwargs.get('unprotected', 0)
    download_policy = kwargs.get('download_policy', 'background')
    mirror_on_sync  = kwargs.get('mirror_on_sync', 1)
    verify_ssl      = kwargs.get('verify_ssl', 1)

    organizations = check_settings(hostname, username, password, "/katello/api/organizations")
    for group in organizations:
        if group['name'] == organization:
            organization_id = group['id']
    if 'organization_id' not in locals():
        raise ValueError("Unable to find organization - check spelling")

    products = check_settings(hostname, username, password,
                              "/katello/api/organizations/" + str(organization_id) + "/products")
    for product in products:
        if product['name'] == product_name:
            product_id = product['id']
    gpg_keys = check_settings(hostname, username, password,
                              "/katello/api/gpg_keys?organization_id=" + str(organization_id))
    for key in gpg_keys:
        if key['name'] == os.path.basename(gpg_key):
            gpg_id = key['id']

    if 'product_id' not in locals():
        raise ValueError("Unable to find product - check spelling")
    elif 'gpg_key' not in locals():
        raise ValueError("Unable to find gpg_key - check URL")
    else:
        response = requests.post('https://' + hostname +
                                 '/katello/api/repositories',
                                 data=json.dumps({'name': repo_name,
                                                  'label': repo_name.replace(" ", "_"),
                                                  'product_id': product_id,
                                                  'url': repo_url,
                                                  'content_type': content_type,
                                                  'checksum_type': 'sha256',
                                                  'download_policy': download_policy,
                                                  'mirror_on_sync': mirror_on_sync,
                                                  'verify_ssl': verify_ssl,
						  'unprotected': unprotected,
                                                  'gpg_key_id': gpg_id,}),
                                 headers={'Content-Type': 'application/json'},
                                 auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 200:
        return data

    elif data['code'] == 422:
        return 'A repo with this name already exists'

    else:
        raise ValueError(str(data['code']) + " - " + json.dumps(data['content']))

def create_content_view(hostname, username, password, organization,
                        content_view_name, content_repos):

    organizations = check_settings(hostname, username, password, "/katello/api/organizations")
    for group in organizations:
        if group['name'] == organization:
            organization_id = group['id']
    if 'organization_id' not in locals():
        raise ValueError("Unable to find organization - check spelling")

    repo_ids = []
    repos = check_settings(hostname, username, password,
                           "/katello/api/repositories?organization_id=" + str(organization_id))
    for repo_name, repodata in content_repos.iteritems():
        if repo_name != "sync_plan":
            for repository in repos:
                if repo_name == repository['name']:
                    repo_ids.append(repository['id'])

    if 'sync_plan' in content_repos.keys():
        if len(repo_ids)+1 != len(content_repos.values()):
            raise ValueError('Unable to find repo in provided list (it doesn\'t exist yet.)'
                             + ' or too many repos found (make sure you don\'t have the same'
                             + ' repo in two products. Use a composite view instead.)')
    else:
        if len(repo_ids) != len(content_repos.values()):
            raise ValueError('Unable to find repo in provided list (it doesn\'t exist yet.)'
                             + ' or too many repos found (make sure you don\'t have the same'
                             + ' repo in two products. Use a composite view instead.)')

    response = requests.post('https://' + hostname +
                             '/katello/api/content_views',
                             data=json.dumps({'organization_id': organization_id, 'name':
                                              content_view_name, 'description': content_view_name,
                                              'label': content_view_name.replace(" ", "_"),
                                              'repository_ids': repo_ids}),
                             headers={'Content-Type': 'application/json'},
                             auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 200:
        return data
    elif data['code'] == 422:
        return 'A product with this name already exists'
    else:
        raise ValueError(str(data['code']) + " - " + json.dumps(data['content']))

def create_composite_view(hostname, username, password, organization,
                          composite_view_name, content_views):

    organizations = check_settings(hostname, username, password, "/katello/api/organizations")
    for group in organizations:
        if group['name'] == organization:
            organization_id = group['id']
    if 'organization_id' not in locals():
        raise ValueError("Unable to find organization - check spelling")

    content_view_ids = []
    existing_content_views = check_settings(hostname, username, password,
                                   "/katello/api/content_views?organization_id=" +
                                   str(organization_id))

    for view in existing_content_views:
        if view['name'] in content_views: 
          content_view_ids.append({"latest": 1, "content_view_id": view['id']})
    if len(content_view_ids) != len(content_views):
        raise ValueError('Unable to find the listed content_views')

    response = requests.post('https://' + hostname +
                             '/katello/api/content_views',
                             data=json.dumps({'organization_id': organization_id, 'name':
                                              composite_view_name,
                                              'description': composite_view_name,
                                              'label': composite_view_name.replace(" ", "_"),
                                              'composite': 1}),
                             headers={'Content-Type': 'application/json'},
                             auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 200:
        response = requests.put('https://' + hostname +
                                 '/katello/api/content_views/' + str(data['content']['id']) + 
                                 '/content_view_components/add',
                                 data=json.dumps({'components': content_view_ids }),
                                 headers={'Content-Type': 'application/json'},
                                 auth=HTTPBasicAuth(username, password))

        data = _load_response(response)

        if data['code'] == 200:
            return data
        else:
            raise ValueError(str(data['code']) + " - " + json.dumps(data['content']))

    elif data['code'] == 422:
        return 'A product with this name already exists'
    else:
        raise ValueError(str(data['code']) + " - " + json.dumps(data['content']))

def sync_product_repos(hostname, username, password,
                       organization,
                       product_name):

    organizations = check_settings(hostname, username, password, "/katello/api/organizations")
    for group in organizations:
        if group['name'] == organization:
            organization_id = group['id']
    if 'organization_id' not in locals():
        raise ValueError("Unable to find organization - check spelling")

    products = check_settings(hostname, username, password,
                              "/katello/api/products?organization_id=" + str(organization_id))
    for product in products:
        if product['name'] == product_name:
            product_id = product['id']
    if 'product_id' not in locals():
        raise ValueError("Unable to find product - check spelling")
    else:
        response = requests.post('https://' + hostname + '/katello/api/products/' +
                                 str(product_id) + '/sync', data=json.dumps({'id': product_id}),
                                 headers={'Content-Type': 'application/json'},
                                 auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 200:
        return data
    elif data['code'] == 202:
        return ('Sync initiated and in progress. View progress in your web browser at:\n' +
                'https://' + hostname + '/foreman_tasks/tasks\n' +
                'https://' + hostname + 'katello/sync_management\n')
    elif data['code'] == 422:
        raise ValueError('Unable to synchronize any repository. You either do not have the ' +
                         'permission to synchronize or the selected product contains no ' +
                         'repositories to sync.')
    else:
        raise ValueError(str(data['code']) + ": " + json.dumps(data['content']))

def create_environment(hostname, username, password, organization,
                       environment_name, *args, **kwargs):
    parent_environment = kwargs.get('parent_environment', 'Library')

    organizations = check_settings(hostname, username, password, "/katello/api/organizations")
    for group in organizations:
        if group['name'] == organization:
            organization_id = group['id']
    if 'organization_id' not in locals():
        raise ValueError("Unable to find organization - check spelling")

    existing_environments = check_settings(hostname, username, password,
                                           "/katello/api/environments")
    for env in existing_environments:
        if env['name'] == parent_environment:
            parent_id = env['id']
    if 'parent_id' not in locals():
        raise ValueError("Unable to find parent environment")

    response = requests.post('https://' + hostname + '/katello/api/environments',
                             data=json.dumps({'organization_id': organization_id,
                                              'name': environment_name,
                                              'prior_id': parent_id}),
                             headers={'Content-Type': 'application/json'},
                             auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 200:
        return data
    elif data['code'] == 422:
        return 'A Lifecycle Environment with this name already exists'
    else:
        raise ValueError(str(data['code']) + " - " + json.dumps(data['content']))

def create_activation_key(hostname, username, password, organization,
                          name, *args, **kwargs):

    environment  = kwargs.get('environment', None) #This is the pupet env. Need to set to salt env.
    content_view = kwargs.get('content_view', None)
    max_hosts    = kwargs.get('max_hosts', 0)

    organizations = check_settings(hostname, username, password, "/katello/api/organizations")
    for group in organizations:
        if group['name'] == organization:
            organization_id = group['id']
    if 'organization_id' not in locals():
        raise ValueError("Unable to find organization - check spelling")

    post_data = {'organization_id': organization_id, 'name': name}

    if environment != None:
        environments = check_settings(hostname, username, password, "/katello/api/environments")
        for env in environments:
            if env['name'] == environment:
                environment_id = env['id']

        if 'environment_id' not in locals():
            raise ValueError("Unable to find Lifecycle Environment " +
                             "to associate to activaion key - check spelling")

        post_data['environment_id'] = environment_id

    if content_view != None:
        content_views = check_settings(hostname, username, password, "/katello/api/content_views")
        for view in content_views:
            if view['name'] == content_view:
                content_view_id = view['id']

        if 'content_view_id' not in locals():
            raise ValueError("Unable to find Content View to associate " +
                             "to activaion key - check spelling")

        post_data['content_view_id'] = content_view_id

    response = requests.post('https://' + hostname + '/katello/api/activation_keys',
                             data=json.dumps(post_data),
                             headers={'Content-Type': 'application/json'},
                             auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 200:
        return data
    elif data['code'] == 422:
        if ("Validation failed: Content view '" + content_view  +"' is not in environment"
                in data['content']['displayMessage']):
            raise ValueError("Content view is not in Lifecycle Environment. " +
                             "Has it been promoted to this environment yet?")
        else:
            return 'An activation key with this name already exists ' + json.dumps(data['content'])
    else:
        raise ValueError(str(data['code']) + " - " + json.dumps(data['content']))

def create_compute(hostname, username, password,
                   name, provider, *args, **kwargs):
    location             = kwargs.get('location', None)
    organization         = kwargs.get('organization', None)
    url                  = kwargs.get('url', None)
    user                 = kwargs.get('user', None)
    password             = kwargs.get('password', None)
    datacenter           = kwargs.get('datacenter', None)           # OVirt, vmware
    region               = kwargs.get('region', None)               # Amazon EC2
    tenant               = kwargs.get('tenant', None)               # openstack
    server               = kwargs.get('server', None)               # vmware
    set_console_password = kwargs.get('set_console_password', True) # vmware
    display_type         = kwargs.get('display_type', None)	    # LibVirt
    caching_enabled      = kwargs.get('caching_enabled', True)      # vmware

    post_data = {'name': name, 'provider': provider}

    if provider == 'Vmware':
        post_data['user'] = user
        post_data['password'] = password
        post_data['datacenter'] = datacenter
        post_data['server'] = server
        post_data['set_console_password'] = set_console_password
        post_data['caching_enabled'] = caching_enabled

    elif provider == 'EC2':
        post_data['user'] = user
        post_data['password'] = password
        post_data['region'] = region

    elif provider == 'Libvirt':
        post_data['url'] = url
        post_data['set_console_password'] = set_console_password
        post_data['display_type'] = display_type

    elif provider == 'Ovirt':
        post_data['url'] = url
        post_data['user'] = user
        post_data['password'] = password
        post_data['datacenter'] = datacenter

    elif provider == 'Openstack':
        post_data['url'] = url
        post_data['user'] = user
        post_data['password'] = password
        post_data['tenant'] = tenant

    elif provider == 'Rackspace':
        post_data['url'] = url

    elif provider != 'GCE':
        raise ValueError('Provider must be one of type:\n' +
                         '"Libvirt", "Ovirt", "EC2", "Vmware", "Openstack", "Rackspace" or "GCE"')

    response = requests.post('https://' + hostname + '/api/compute_resources',
                             data=json.dumps(post_data),
                             headers={'Content-Type': 'application/json'},
                             auth=HTTPBasicAuth(username, password))

    data = _load_response(response)

    if data['code'] == 200:
        return data
    elif data['code'] == 422:
        return 'An Compute Provider with this name already exists ' + json.dumps(data['content'])
    else:
        raise ValueError(str(data['code']) + " - " + json.dumps(data['content']))

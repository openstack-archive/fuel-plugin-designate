notice('MODULAR: designate/designate.pp')

$designate_hash             = hiera_hash('fuel-plugin-designate', {})
$public_vip                 = hiera('public_vip')
$management_vip             = hiera('management_vip')
$database_vip               = hiera('database_vip', $management_vip)
$public_ssl_hash            = hiera('public_ssl')
$mysql_hash                 = hiera_hash('mysql_hash', {})

$network_metadata           = hiera_hash('network_metadata', {})

$public_address = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}

$debug                      = hiera('debug', true)
$verbose                    = hiera('verbose', true)
$rabbit_hash                = hiera_hash('rabbit_hash', {})
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$amqp_hosts                 = hiera('amqp_hosts')
$rabbit_hosts               = split($amqp_hosts, ',')

$db_host                    = pick($designate_hash['metadata']['db_host'], $database_vip)
$db_user                    = pick($designate_hash['metadata']['db_user'], 'designate')
$db_name                    = pick($designate_hash['metadata']['db_name'], 'designate')
$db_password                = pick($designate_hash['metadata']['db_password'], 'designate')
$database_connection        = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?charset=utf8&read_timeout=60"

$designate_auth_strategy    = "keystone"
$keystone_endpoint          = hiera('service_endpoint', $management_vip)
$designate_tenant           = pick($designate_hash['metadata']['tenant'],'services')
$designate_user             = pick($designate_hash['metadata']['user'],'designate')
$designate_user_password    = pick($designate_hash['metadata']['user_password'],'designate')
$enable_api_v2              = hiera('enable_api_v2', true)

if $designate_hash['metadata']['enabled'] {
  class { 'designate':
    verbose             => $verbose,
    debug               => $debug,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_port         => $rabbit_port,
    rabbit_userid       => $rabbit_hash['user'],
    rabbit_password     => $rabbit_hash['password'],
  }

  class { 'designate::agent': }

  class { 'designate::db':
    database_connection => $database_connection,
  }

  class { 'designate::client': }

  class { 'designate::api':
    auth_strategy        => $designate_auth_strategy,
    keystone_host        => $keystone_endpoint,
    keystone_protocol    => $public_protocol,
    keystone_tenant      => $designate_tenant,
    keystone_user        => $designate_user,
    keystone_password    => $designate_user_password,
    enable_api_v2        => $enable_api_v2,
  }

  class { 'designate::sink': }

  class { 'designate::central': }

  firewall { '207 designate-api' :
    dport   => '9001',
    proto   => 'tcp',
    action  => 'accept',
  }

}

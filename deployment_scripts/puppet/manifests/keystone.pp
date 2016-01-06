notice('MODULAR: designate/keystone.pp')

$designate_hash             = hiera_hash('fuel-plugin-designate', {})
$public_ip                  = hiera('public_vip')
$management_ip              = hiera('management_vip')
$public_ssl                 = hiera('public_ssl')
$region                     = hiera('region', 'RegionOne')


$public_protocol = $public_ssl['services'] ? {
  true    => 'https',
  default => 'http',
}

$public_address = $public_ssl['services'] ? {
  true    => $public_ssl['hostname'],
  default => $public_ip,
}

$api_bind_port  = '9001'

$tenant         = pick($designate_hash['metadata']['tenant'], 'services')
$public_url     = "${public_protocol}://${public_address}:${api_bind_port}"
$admin_url      = "http://${management_ip}:${api_bind_port}"

#################################################################

class { 'designate::keystone::auth':
  password     => $designate_hash['metadata']['user_password'],
  service_type => 'dns',
  region       => $region,
  tenant       => $tenant,
  public_url   => $public_url,
  admin_url    => $admin_url,
  internal_url => $admin_url,
}

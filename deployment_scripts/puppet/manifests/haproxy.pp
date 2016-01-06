notice('MODULAR: designate/haproxy.pp')

$designate_hash    = hiera_hash('fuel-plugin-designate', {})
$public_ssl_hash = hiera('public_ssl')
$network_metadata = hiera_hash('network_metadata')

$use_designate = pick($designate_hash['metadata']['enabled'], true)


$designate_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['designate']), 'designate/api')

if ($use_designate) {
  $server_names        = pick(hiera_array('designate_names', undef),
                              keys($designate_address_map))
  $ipaddresses         = pick(hiera_array('designate_ipaddresses', undef),
                              values($designate_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure designate ha proxy
  Openstack::Ha::Haproxy_service {
    ipaddresses            => $ipaddresses,
    public_virtual_ip      => $public_virtual_ip,
    server_names           => $server_names,
    public                 => true,
    public_ssl             => $public_ssl_hash['services'],
    haproxy_config_options => {
      option => ['httpchk GET /', 'httplog','httpclose'],
    },
  }

  openstack::ha::haproxy_service { 'designate-api':
    order               => '230',
    listen_port         => 9001,
    internal_virtual_ip => $internal_virtual_ip,
  }

}

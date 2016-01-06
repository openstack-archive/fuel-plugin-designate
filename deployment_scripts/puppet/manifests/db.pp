notice('MODULAR: designate/db.pp')

$node_name      = hiera('node_name')

$designate_hash    = hiera_hash('fuel-plugin-designate', $default_fuel_plugin_designate)
$mysql_hash     = hiera_hash('mysql_hash', {})

$designate_enabled = pick($designate_hash['metadata']['enabled'], false)
$database_vip   = hiera('database_vip')

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_user     = pick($designate_hash['metadata']['db_user'], 'designate')
$db_name     = pick($designate_hash['metadata']['db_name'], 'designate')
$db_password = pick($designate_hash['metadata']['db_password'], $mysql_root_password)

$db_host          = pick($designate_hash['metadata']['db_host'], $database_vip)
$db_create        = pick($designate_hash['metadata']['db_create'], $mysql_db_create)
$db_root_user     = pick($designate_hash['metadata']['root_user'], $mysql_root_user)
$db_root_password = pick($designate_hash['metadata']['root_password'], $mysql_root_password)

$allowed_hosts = [ $node_name, 'localhost', '127.0.0.1', '%' ]

validate_string($mysql_root_user)

if $designate_enabled and $db_create {

  class { 'galera::client':
    custom_setup_class => hiera('mysql_custom_setup_class', 'galera'),
  }

  class { 'designate::db::mysql':
    user          => $db_user,
    password      => $db_password,
    dbname        => $db_name,
    allowed_hosts => $allowed_hosts,
  }

  class { 'osnailyfacter::mysql_access':
    db_host     => $db_host,
    db_user     => $db_root_user,
    db_password => $db_root_password,
  }

  Class['galera::client'] ->
    Class['osnailyfacter::mysql_access'] ->
      Class['designate::db::mysql']

}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server

include node_manager

Node_group {
  provider => 'https',
}

node_group { 'Puppet Masters':
  ensure               => 'present',
  classes              => {'role::puppet::master' => {}},
  environment          => 'production',
  override_environment => false,
  parent               => 'All Nodes',
  rule                 => ['=', 'name', $facts['fqdn']],
}

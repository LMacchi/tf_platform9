include node_manager

Node_group {
  provider => 'https',
}

node_group { 'Compile Masters':
  ensure               => 'present',
  classes              => {'role::puppet::cm' => {}},
  environment          => 'production',
  override_environment => false,
  parent               => 'All Nodes',
  rule                 => ['=', ['trusted', 'extensions', 'pp_role'], 'puppet::cm']
}

node_group { 'PE Master':
  ensure => 'present',
  rule   => ['or', ['=', ['trusted', 'extensions', 'pp_role'], 'puppet::cm'], ['=', 'name', $facts['fqdn']]],
}



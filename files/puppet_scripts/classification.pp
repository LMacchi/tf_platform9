node_group { 'Puppet Masters':
  ensure               => 'present',
  classes              => {'role::puppet::master' => {}},
  environment          => 'production',
  override_environment => false,
  parent               => 'All Nodes',
  rule                 => ['=', ['trusted', 'extensions', 'pp_role'], 'puppet::master']
}

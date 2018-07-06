node_group { 'Packages Collection':
  ensure               => 'present',
  classes              => {
  'puppet_enterprise::profile::agent' => {
    'package_inventory_enabled' => true
  }
},
  environment          => 'production',
  override_environment => 'false',
  parent               => 'All Nodes',
  rule                 => ['and',
  ['~', 'name', '.*']],
}

# the env $name must be unique
define runit::service::env( $service, $value, $ensure = present ) {
  
  $envdir = "/etc/sv/${service}/env"
  
  # create this directory if at least one environment variable is defined
  if !defined( File["/etc/sv/${service}/env"] ) {
    file{ "/etc/sv/${service}/env":
      ensure  => directory,
      # all unmanaged envs. will be removed
      recurse => true,
      purge   => true,
    }
  }
  
  # runit::directory { $envdir: }
  file { "${envdir}/${name}":
    ensure => $ensure,
    content => "${value}\n",
  }

}

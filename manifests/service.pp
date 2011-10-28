define runit::service (
  $user    = root,       # the service's user name
  $group   = root,       # the service's group name
  $enable  = true,       # shall the service be linked to /etc/service
  $ensure  = present,    # shall the service be present in /etc/sv
  $logger  = false,      # shall we setup an logging service
  # either one of these must be given:
  $source  = undef,      # either source or content must be defined; 
  $content = undef       # this will be the run script /etc/sv/$name/run
) {

  # resource defaults
  File { owner => root, group => root, mode => 644 }

  $svbase = "/etc/sv/${name}"
  
  # creating the logging sub-service, if requested
  if $logger == true {
    runit::service{ "${name}/log":
      user => $user, group => $group, enable => false, ensure => $ensure, logger => false,
      content => template('runit/logger_run.erb'),
    }
  }
  
  # the main service stuff
  file {
    "${svbase}":
      ensure => $ensure ? {
        present => directory,
        default => absent,
        },
        purge => true,
      ;
    "${svbase}/run":
      content => $content,
      source  => $source,
      ensure  => $ensure,
      mode    => 755,
      ;
  }

  # eventually enabling the service
  if $ensure == present and $enable == true {
    $_ensure_enabled = present
  } else {
    $_ensure_enabled = absent
  }

  debug( "Service ${name}: ${_ensure_enabled}" )

  runit::service::enabled { $name: ensure => $_ensure_enabled }
}

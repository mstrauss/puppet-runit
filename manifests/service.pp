define runit::service (
  $user    = root,       # the service's user name
  $group   = root,       # the service's group name
  $enable  = true,       # shall the service be linked to /etc/service
  $ensure  = present,    # shall the service be present in /etc/sv
  # either one of these three must be declared - it defines the content of the run script /etc/sv/$name/run
  $command = undef,      # the most simple way;  just state command here - it may not daemonize itself,
                         # but rather stay in the foreground;  all output is logged automatically to $logdir/current
                         # this uses a default template which provides logging
  $source  = undef,      # specify a source file on your puppet master 
  $content = undef,      # specify the content directly (mostly via 'template')
  # service directory - this is required if you use 'command'
  $rundir  = undef,
  # logging stuff
  $logger  = true,       # shall we setup an logging service;  if you use 'command' before, 
                         # all output from command will be logged automatically to $logdir/current
  $_logdir  = undef
) {
  
  # using the following construct, because '$logdir = "${rundir}/log"' in the
  # define statement produces compilation warnings  
  if $_logdir == undef {
    $logdir = "${rundir}/log"
  } else {
    $logdir = $_logdir
  }

  # FixMe: Validate parameters
  # fail("Only one of 'command', 'content', or 'source' parameters is allowed")

  if $command != undef and $rundir == undef {
    fail( "You need to specify 'rundir': That's the directory from which the service will be started.")
  }

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
      content => $content ? {
        undef   => template('runit/run.erb'),
        default => $content,
      },
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

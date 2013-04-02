define runit::service::enabled( $ensure = present, $timeout ) {

  # enabling the service by creating a symlink in /etc/service
  file { "/etc/service/${name}":
    target => $ensure ? {
      present => "/etc/sv/${name}",
      default => undef,
    },
    ensure => $ensure ? {
      present => link,
      default => absent,
    },
  }

  if $ensure == present {

    # subscribe to any run file changes
    File["/etc/sv/${name}/run"] ~> Runit::Service::Enabled[$name]

    # we also require notification from all environment variables
    Runit::Service::Env <| service == $name |> {
      notify +> Runit::Service::Enabled[$name]
    }

    exec { "sv restart ${name}":
      subscribe   => File["/etc/service/${name}"],
      # last command is true, so this resource never fails
      command     => "/usr/bin/sv -w ${timeout} force-restart '/etc/sv/${name}'; true",
      # we desperately need the supervise directory to restart a service
      onlyif      => "/usr/bin/test -d '/etc/sv/${name}/supervise'",
      refreshonly => true,
    }

  } else {

    # Stop the service in THIS sequence:
    #   1. remove /etc/services link
    #   2. force-shutdown /etc/sv/*
    #   3. remove /etc/sv stuff
    #   4. manage users, groups, whatever

    exec { "sv exit ${name}":
      require     => File["/etc/service/${name}"],
      before      => File["/etc/sv/${name}"],
      # we wait a few seconds just in case this is the firstmost service activation
      # then the supervise directory need to be created (automically) by runit
      command     => "/usr/bin/sv -w ${timeout} force-shutdown '/etc/sv/${name}'; true",
      # when "/etc/sv/${name}" is not there, do not exec
      onlyif      => "/usr/bin/test -d '/etc/sv/${name}'",
    }

    # if we have users/groups, we need to remove them AFTER stopping the server
    User  <||> { require +> Exec["sv exit ${name}"] }
    Group <||> { require +> Exec["sv exit ${name}"] }

  }
}

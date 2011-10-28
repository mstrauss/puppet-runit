define runit::service::enabled( $ensure = present ) {

  # enabling the service by creating a symlink in /etc/service
  file { "/etc/service/${name}":
    target => "/etc/sv/${name}",
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
      # we wait a few seconds just in case this is the firstmost service activation
      # then the supervise directory need to be created (automically) by runit
      command     => "/bin/sleep 3; /usr/bin/sv -w 60 restart /etc/sv/${name}",
      refreshonly => true,
    }

  }
  
}

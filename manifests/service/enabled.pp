# we always create a symlink under /etc/service, but for disabled services we
# create /etc/service/$name/down which is used by runit
#
# | ensure  | enabled | outcome (if managed)                |
# |---------|---------|-------------------------------------|
# | present | true    | enable & start service              |
# | present | false   | disable & stop service              |
# | absent  | -       | stop service & delete /etc/sv/$name |
#

define runit::service::enabled( $ensure, $managed, $enabled, $timeout ) {

  if $managed {

    # command to start/restart the service
    if $ensure =~ /present|true/ and $enabled == true {
      exec { "sv restart ${name}":
        # last command is true, so this resource never fails
        command     => "/usr/bin/sv -w ${timeout} force-restart '/etc/sv/${name}'; true",
        # we desperately need the supervise directory to restart a service
        onlyif      => "/usr/bin/test -d '/etc/sv/${name}/supervise'",
        refreshonly => true,
      }
    }

    # command to stop the service
    if ( $ensure =~ /present|true/ and $enabled == false ) or $ensure =~ /absent|false/ {
      exec { "sv force-shutdown ${name}":
        command     => "/usr/bin/sv -w ${timeout} force-shutdown '/etc/sv/${name}'; true",
        refreshonly => true,
      }
    }

    # enabling the service by creating a symlink in /etc/service
    file { "/etc/service/${name}":
      target => "/etc/sv/${name}",
      ensure => $ensure ? {
        /true|present/ => link,
        default        => absent,
      },
    }

    if $ensure =~ /present|true/ {

      file { "/etc/sv/${name}/down":
        content => '',
        ensure  => $enabled ? {
          true    => absent,
          false   => $ensure,
        },
      }

      if $enabled {

        File["/etc/sv/${name}/down"] ~> Exec["sv restart ${name}"]

        # subscribe to any run file changes
        File["/etc/sv/${name}/run"] ~> Runit::Service::Enabled[$name]

        # we also require notification from all environment variables
        Runit::Service::Env <| service == $name |> {
          notify +> Runit::Service::Enabled[$name]
        }

      } else {

        File["/etc/sv/${name}/down"] ~> Exec["sv force-shutdown ${name}"]

        # if we have users/groups, we need to remove them AFTER stopping the server
        User  <||> { require +> Exec["sv force-shutdown ${name}"] }
        Group <||> { require +> Exec["sv force-shutdown ${name}"] }
      }

    } else {

      # ensure == absent
      exec { "check service ${name}":
        command => '/bin/true',
        onlyif  => "/usr/bin/sv check /etc/sv/${name}"
      }
      ~> Exec["sv force-shutdown ${name}"] -> File["/etc/sv/${name}"]
    }

  }

}

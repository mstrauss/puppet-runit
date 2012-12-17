class runit( $ensure = present ) {

  package { runit: ensure => $ensure }

  if $ensure == present {
    file {
      '/etc/sv':
        ensure => directory,
        ;
      '/etc/service':
        ensure => directory,
        ;
    }

  }

}

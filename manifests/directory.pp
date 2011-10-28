define runit::directory( $ensure = directory ) {
  
  if !defined( File[$name] ) {
    file{ $name: ensure => $ensure }
  }
  
}

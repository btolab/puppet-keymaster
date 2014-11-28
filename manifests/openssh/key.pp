# This defines an openssh key
define keymaster::openssh::key (
  $ensure   = present,
  $filename = undef,
  $keytype  = 'rsa',
  $length   = '2048',
  $maxdays  = undef,
  $mindate  = undef,
  $force    = false,
  $options  = undef
) {

  validate_re($keytype, ['^rsa$','^dsa$'])

  if $filename {
    $_filename = $filename
  } else {
    $_filename = "id_${keytype}"
  }

  case $keytype {
    'dsa':{
      $_length = '1024'
    }
    default:{
      $_length = $length
    }
  }

  validate_re(
    $name,
    '^[A-Za-z0-9][A-Za-z0-9_.:@-]+$',
    "${name} must start with a letter or digit, and may only contain the characters A-Za-z0-9_.:@-"
  )

  $tag = regsubst($name, '@', '_at_')

  # generate exported resources for the keymaster to realize
  @@keymaster::openssh::key::generate { $name:
    ensure  => $ensure,
    force   => $force,
    keytype => $keytype,
    length  => $_length,
    maxdays => $maxdays,
    mindate => $mindate,
    tag     => $tag,
  }

  # generate exported resources for the ssh client host to realize
  @@keymaster::openssh::key::deploy { $name:
    ensure   => $ensure,
    filename => $_filename,
    tag      => $tag,
  }

  # generate exported resources for the ssh server host to realize
  @@keymaster::openssh::key::authorized_key { $name:
    ensure  => $ensure,
    options => $options,
    tag     => $tag,
  }

}
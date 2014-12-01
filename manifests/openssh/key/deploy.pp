# This private resource deploys a key pair into a user's account
# This resource should not be called in a manafiest and should only be
# used by keymaster::openssh::key
define keymaster::openssh::key::deploy (
  $user,
  $filename,
  $ensure = 'present',
) {

  # get homedir and primary group of $user
  $home  = getparam(User[$user],'home')
  $group = getparam(User[$user],'group')

  # filename of private key on the keymaster (source)
  $key_src_file = "${::keymaster::keystore_openssh}/${name}/key"

  # filename of private key on the ssh client host (target)
  $key_tgt_file = "${home}/.ssh/${filename}"

  # contents of public key on the keymaster
  $key_src_content_pub = file("${key_src_file}.pub", '/dev/null')



  # If 'absent', revoke the client keys
  if $ensure == 'absent' {
    file {[ $key_tgt_file, "${key_tgt_file}.pub" ]: ensure  => 'absent' }

  # test for homedir and primary group
  } elsif ! $home {
    #notify { "Can't determine home directory of user $user": }
    err ( "Can't determine home directory of user ${user}" )
  } elsif ! $group {
    #notify { "Can't determine primary group of user $user": }
    err ( "Can't determine primary group of user ${user}" )

  # If syntax of pubkey checks out, install keypair on client
  } elsif ( $key_src_content_pub =~ /^(ssh-...) ([^ ]+)/ ) {
    $keytype = $1
    $modulus = $2

    # QUESTION: what about the homedir?  should we create that if 
    # not defined also? I think not.
    #
    # create client user's .ssh file if defined already
    if ! defined(File[ "${home}/.ssh" ]) {
      file { "${home}/.ssh":
        ensure => 'directory',
        owner  => $user,
        group  => $group,
        mode   => '0700',
      }
    }

    file { $key_tgt_file:
      ensure  => 'file',
      content => file($key_src_file, '/dev/null'),
      owner   => $user,
      group   => $group,
      mode    => '0600',
      require => File["${home}/.ssh"],
    }
    
    file { "${key_tgt_file}.pub":
      ensure  => 'file',
      content => "${keytype} ${modulus} ${name}\n",
      owner   => $user,
      group   => $group,
      mode    => '0644',
      require => File["${home}/.ssh"],
    }

  # Else the keymaster has not realized the sshauth::keys::master resource yet
  } else {
    notify { "Private key file ${key_src_file} for key ${name} not found on keymaster; skipping ensure => present": }
  }

}
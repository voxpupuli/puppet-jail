
#permute { "jailbase":
#  resource  => "jailbase",
#  unique    => {
#    release => [ '9.1-RELEASE', '8.3-RELEASE'], 
#  },
#  common    => {
#    baseurl => "http//ftp4.freebsd.org/pub/FreeBSD/releases/amd64/amd64/<%=release %>/base.txz",
#  },
#}

#jailbase { "freebsd91amd64":
#  url => "http//ftp4.freebsd.org/pub/FreeBSD/releases/amd64/amd64/9.1-RELEASE/base.txz",
#}

Jail {
  ensure => absent,
  source => '/jails/base.txz',
}

jail { "/jails/test01": }
jail { "/jails/test02": }


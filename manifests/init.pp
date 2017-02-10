# Class: service_diffusion_sympa
# ===========================
#
# La classe service_diffusion_sympa permet d'instancier un serveur
# sympa complet depuis les sources avec serveur web, serveur mail, …
#
# Parameters
# ----------
#
# None
#
# Variables
# ----------
#
#  - `$version`     : version sympa à installer
#  - `$prefix`      : Chemin d'installation de sympa
#  - `$basename`    : domaine de nom MX des listes de diffusion
#  - `$listmasters` : listees adresses mail des listmaster
#  - `db_name`      : nom de la base de données
#  - `db_passwd`    : mot de passe d'accès à la base de données
#  - `ldap_passwd`  : mot de passe d'accès à l'annuaire LDAP
#
# Examples
# --------
#
# @example
#    class {'service_diffusion_sympa':
#        version     => '6.2.16',
#        prefix      => '/usr/local/sympa',
#        listmasters => ['listmaster@mydomain.tld'],
#        db_name     => 'sympa_db',
#        db_passwd   => '7qEyNJTdOFEU',
#        ldap_passwd => 'lH8wXvdFet0C',
#        ldap_host   => 'zldap.mydomain.tld',
#        ldap_dn     => 'uid=zimbra,cn=admins,cn=zimbra',
#    }
#
# Authors
# -------
#
# Olivier Le Monnier <olm@unicaen.fr>
#
# Copyright
# ---------
#
# Copyright 2015 Olm
#
class service_diffusion_sympa {

  # Quelques variables
  $version   = '6.2.16'
  $prefix    = '/usr/local/sympa'
  $ldap_host = 'wzldap01.unicaen.fr'
  $ldap_dn   = 'uid=zimbra,cn=admins,cn=zimbra'
  $url       = "https://${basename}/sympa"
  $escaped_basename = split($basename, '[.]').join('\.')
  $ldap_suffix      = split($domain, '[.]').join(',dc=')
  $full_ldap_suffix = split($basename, '[.]').join(',dc=')
  
  ## Installation des paquets nécessaires
  # --
  # Pour la compilation
  package {'wget':      ensure => present }
  package {'gcc':       ensure => present }
  package {'libc6-dev': ensure => present }
  package {'make':      ensure => present }
  package {'unzip':     ensure => present }
  package {'libaio1':   ensure => present }
  # Modules perl essentiels
  package {'libhtml-format-perl':              ensure => present }
  package {'libcgi-fast-perl':                 ensure => present }
  package {'libdatetime-perl':                 ensure => present }
  package {'libhtml-parser-perl':              ensure => present }
  package {'libxml-libxml-perl':               ensure => present }
  package {'libintl-perl':                     ensure => present }
  package {'libfile-nfslock-perl':             ensure => present }
  package {'libmime-encwords-perl':            ensure => present }
  package {'libfile-copy-recursive-perl':      ensure => present }
  package {'libmime-tools-perl':               ensure => present }
  package {'libunicode-linebreak-perl':        ensure => present }
  package {'libhtml-stripscripts-parser-perl': ensure => present }
  package {'libnet-cidr-perl':                 ensure => present }
  package {'libio-stringy-perl':               ensure => present }
  package {'libcgi-pm-perl':                   ensure => present }
  package {'libterm-progressbar-perl':         ensure => present }
  package {'libtemplate-perl':                 ensure => present }
  package {'libdatetime-format-mail-perl':     ensure => present }
  # Modules perl complémentaires
  # --
  # Téléchargement des archives
  package {'libarchive-zip-perl': ensure => present }
  # Génération des pages d'archives
  package {'mhonarc':             ensure => present }
  # => Liens symboliques pour intégration de MHonArc à perl
  file {'/usr/share/perl5/MHonArc':
    ensure => link,
    target => '/usr/share/mhonarc/MHonArc' }
  file {'/usr/share/perl5/mhamain.pl':
    ensure => link,
    target => '/usr/share/mhonarc/mhamain.pl' }
  file {'/usr/share/perl5/osinit.pl':
    ensure => link,
    target => '/usr/share/mhonarc/osinit.pl' }
  # Composition de messages HTML depuis l'interface web
  package {'libmime-lite-html-perl':     ensure => present }
  # Pilotage des sous-processus bulk
  package {'libproc-processtable-perl':  ensure => present }
  # Pour l'authentification CAS
  package {'libauthcas-perl':            ensure => present }
  # Pour réception de messages S/MIME
  package {'libcrypt-openssl-x509-perl': ensure => present }
  # Pour émission de messages S/MIME
  package {'libcrypt-smime-perl':        ensure => present }
  # Prise en charge des bases de données MySQL
  package {'libdbd-mysql-perl':          ensure => present }
  # Vérification et insertion de signatures DKIM
  package {'libmail-dkim-perl':          ensure => present }
  # Protection DMARC
  package {'libnet-dns-perl':            ensure => present }
  # Accès LDAP pour constitution de listes
  package {'libnet-ldap-perl':           ensure => present }
  # WebServices
  package {'libsoap-lite-perl':          ensure => present }
  # Mot de passe chiffrés (réversibles)
  package {'libcrypt-ciphersaber-perl':  ensure => present }

  # Configuration CPAN
  file {'/root/.cpan/':      ensure => directory }
  file {'/root/.cpan/CPAN/': ensure => directory }
  file {'/root/.cpan/CPAN/MyConfig.pm':
    ensure => present,
    source => 'puppet:///modules/service_diffusion_sympa/MyConfig.pm'}
  # Installation depuis CPAN
  # — Module trop ancien sur Debian jessie
  exec {'Installation MIME::Charset depuis CPAN':
    path      => '/usr/bin/',
    require   => File['/root/.cpan/CPAN/MyConfig.pm'],
    command   => 'cpan -i MIME::Charset',
    creates   => '/usr/local/share/perl/5.20.2/MIME/Charset.pm',
    logoutput => 'on_failure',
  }

  ## Installation Oracle
  # --
  # Instantclient
  # — Archives
  file {'/tmp/instantclient-basic.zip':
    ensure => present,
    source => 'puppet:///modules/service_diffusion_sympa/instantclient-basiclite-linux.x64-12.1.0.2.0.zip' }
  file {'/tmp/instantclient-sqlplus.zip':
    ensure => present,
    source => 'puppet:///modules/service_diffusion_sympa/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip' }
  file {'/tmp/instantclient-sdk.zip':
    ensure => present,
    source => 'puppet:///modules/service_diffusion_sympa/instantclient-sdk-linux.x64-12.1.0.2.0.zip'}
  # — Création d'un dossier dédié
  file {'/opt/oracle': ensure => directory }
  # — Dépliage des archives
  exec {'Décompression de instantclient BasicLite':
    path    => '/usr/bin/',
    require => [ File['/tmp/instantclient-basic.zip'],
                 Package['unzip'] ],
    command => 'unzip /tmp/instantclient-basic.zip -d /opt/oracle',
    creates => '/opt/oracle/instantclient_12_1/adrci',
  }
  exec {'Décompression de instantclient SQL+':
    path    => '/usr/bin/',
    require => File['/tmp/instantclient-sqlplus.zip'],
    command => 'unzip /tmp/instantclient-sqlplus.zip -d /opt/oracle',
    creates => '/opt/oracle/instantclient_12_1/glogin.sql',
  }
  exec {'Décompression de instantclient SDK':
    path    => '/usr/bin/',
    require => File['/tmp/instantclient-sdk.zip'],
    command => 'unzip /tmp/instantclient-sdk.zip -d /opt/oracle',
    creates => '/opt/oracle/instantclient_12_1/sdk',
  }
  # — Module perl depuis CPAN
  exec {'Installation DBD:Oracle depuis CPAN':
    require     => [ File['/root/.cpan/CPAN/MyConfig.pm'],
                      Exec['Décompression de instantclient BasicLite',
                          'Décompression de instantclient SQL+',
                          'Décompression de instantclient SDK'] ],
    path        => '/usr/bin:/bin',
    command     => 'cpan -j /root/.cpan/CPAN/MyConfig.pm -i DBD::Oracle',
    environment => ['ORACLE_HOME=/opt/oracle/instantclient_12_1',
                    'LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1'],
    creates     => '/usr/local/lib/x86_64-linux-gnu/perl/5.20.2/DBD/Oracle.pm',
    logoutput   => 'on_failure',
  }

  ## Création de l'utilisateur sympa
  group {'sympa':
    ensure => present,
    before => User['sympa']
  }
  user {'sympa':
    ensure => present,
    gid    => 'sympa',
    home   => "${prefix}"
  }
    
  ## Installation depuis les sources
  # --
  # Récupération des sources
  exec {'Récupération des sources':
    require     => Package['wget'],
    cwd         => '/root',
    command     => "/usr/bin/wget http://www.sympa.org/distribution/sympa-${version}.tar.gz",
    environment => 'http_proxy=http://proxy:3128',
    creates     => "/root/sympa-${version}.tar.gz",
  }
  # Ouverture de l'archive
  exec {'Ouverture de l\'archive':
    require => Exec['Récupération des sources'],
    command => "/bin/tar xzf /root/sympa-${version}.tar.gz -C /usr/src",
    creates => "/usr/src/sympa-${version}/",
  }
  # Configuration des sources
  exec {'Compilation : configure':
    require   => [ Package['gcc'], Exec['Ouverture de l\'archive'], ],
    cwd       => "/usr/src/sympa-${version}/",
    path      => "/usr/src/sympa-${version}:/bin:/usr/bin",
    command   => "configure --prefix=${prefix} --without-initdir",
    creates   => "/usr/src/sympa-${version}/Makefile",
    logoutput => 'on_failure',
  }
  # Compilation
  exec {'Compilation : make':
    require   => [ Package['make'], Exec['Compilation : configure'], ],
    cwd       => "/usr/src/sympa-${version}/",
    command   => '/usr/bin/make',
    creates   => "/usr/src/sympa-${version}/src/cgi/wwsympa-wrapper.fcgi",
    logoutput => 'on_failure',
  }
  # Installation
  exec {'Compilation : make install':
    require     => [ Package['make'], Exec['Compilation : make'], ],
    cwd         => "/usr/src/sympa-${version}/",
    command     => '/usr/bin/make install',
    subscribe   => Exec['Compilation : make'],
    refreshonly => true,
    logoutput   => 'on_failure',
  }
  # Mise à jour de la base en cas d'upgrade
  exec {'Mise à jour de la base':
    require   => Exec['Compilation : make install'],
    cwd       => "${prefix}/",
    command   => "${prefix}/bin/sympa.pl --upgrade",
    unless    => "test $(tail -n1 ${prefix}/etc/data_structure.version) = ${version}",
    logoutput => 'on_failure',
  }

  ## Configuration de la base de données
  file_line {'Moteur de base de données':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?db_type.*',
    line    => 'db_type mysql',
  }
  file_line {'Nom de la base de données':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?db_name.*',
    line    => "db_name ${db_name}",
  }
  file_line {'Serveur de base de données':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?db_host.*',
    line    => 'db_host bdd.unicaen.fr',
  }
  file_line {'Utilisateur de la base de données':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?db_user.*',
    line    => "db_user ad_${db_name}",
  }
  file_line {'Mot de passe de la base de données':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?db_passwd.*',
    line    => "db_passwd ${db_passwd}",
  }

  ## Autres éléments de configuration
  file_line {'Listmaster':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?listmaster.*',
    line    => "listmaster ${listmasters}",
  }
  file_line {'Domaine':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?domain.*',
    line    => "domain ${basename}",
  }
  file_line {'Hôte HTTP':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?http_host.*',
    line    => "http_host ${basename}",
  }
  file_line {'URL':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?wwsympa_url.*',
    line    => "wwsympa_url ${url}",
  }
  file_line {'Traitement des archives':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?process_archive.*',
    line    => 'process_archive on',
  }
  file_line {'URL des fichiers statiques':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?static_content_url.*',
    line    => 'static_content_url /static',
  }
  file_line {'Langues proposées':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?supported_lang.*',
    line    => 'supported_lang fr', # Installer les locales associées
  }
  file_line {'Langue par défaut':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?lang.*',
    line    => 'lang fr',
  }
  file_line {'Titre':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?title.*',
    line    => 'title Listes de diffusion',
  }
  file_line {'Gestion des alias => LDAP':
    ensure  => 'present',
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    line    => "alias_manager ${prefix}/bin/ldap_alias_manager.pl",
  }
  file_line {'Cache binaire des configurations des listes':
    ensure  => 'present',
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => 'cache_list_config',
    line    => "cache_list_config binary_file",
  }
  file_line {'Utilisation du cache en base pour la liste des listes':
    ensure  => 'present',
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => 'db_list_cache',
    line    => "db_list_cache on",
  }
  file_line {'Utilisation de FastCGI':
    ensure  => 'present',
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    line    => "use_fast_cgi 1",
  }

  ## Configuration LDAP
  file {"${prefix}/etc/ldap_alias_manager.conf":
    ensure  => present,
    require => Exec['Compilation : make install'],
    owner   => 'sympa',
    group   => 'sympa',
    mode    => '0644',
    content => template('service_diffusion_sympa/ldap_alias_manager.conf.erb'),
  }
  
  ## Authentification
  file {"${prefix}/etc/auth.conf":
    ensure  => present,
    require => Exec['Compilation : make install'],
    owner   => 'sympa',
    group   => 'sympa',
    mode    => '0644',
    content => template('service_diffusion_sympa/auth.conf.erb'),
  }

  ## Format d'une entrée LDAP
  file {"${prefix}/default/ldap_alias_entry.tt2":
    ensure  => present,
    require => Exec['Compilation : make install'],
    owner   => 'sympa',
    group   => 'sympa',
    mode    => '0644',
    source  => 'puppet:///modules/service_diffusion_sympa/ldap_alias_entry.tt2'
  }

  ## Configuration optionnelle (à étudier…)
  file_line {'Droit de création':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?create_list.*',
    line    => 'create_list listmaster', # Valeur par défaut
  }
  file_line {'Liste noire':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?use_blacklist.*',
    line    => 'use_blacklist send,create_list', # Valeur par défaut
  }
  file_line {'Taille maximale':
    require => Exec['Compilation : make install'],
    path    => '/etc/sympa/sympa.conf',
    match   => '^#?max_size.*',
    line    => 'max_size 5242880', # Valeur par défaut
  }
  # Et encore: capath, cafile, keypasswd, antivirus_*, {anti,}spam_*,
  # title, use_html_editor, use_fast_cgi, http_host

  # Health Check pour créer la base si nécessaire
  exec {'Health-Check':
    require => File_Line['Moteur de base de données',
                  'Nom de la base de données',
                  'Serveur de base de données',
                  'Utilisateur de la base de données',
                  'Mot de passe de la base de données',
                  'Listmaster', 'Domaine', 'URL'],
    cwd     => "${prefix}/",
    command => "${prefix}/bin/sympa.pl --health_check",
  }
  
  # Fichiers d'unité de service Systemd
  file {'/lib/systemd/system/sympa.service':
    ensure => present,
    source => 'puppet:///modules/service_diffusion_sympa/systemd-unitfiles/sympa.service'
  }
  file {'/lib/systemd/system/sympa-archived.service':
    ensure => present,
    source =>
    'puppet:///modules/service_diffusion_sympa/systemd-unitfiles/sympa-archived.service'
  }
  file {'/lib/systemd/system/sympa-bounced.service':
    ensure => present,
    source =>
    'puppet:///modules/service_diffusion_sympa/systemd-unitfiles/sympa-bounced.service'
  }
  file {'/lib/systemd/system/sympa-bulk.service':
    ensure => present,
    source =>
    'puppet:///modules/service_diffusion_sympa/systemd-unitfiles/sympa-bulk.service'
  }
  file {'/lib/systemd/system/sympa-task_manager.service':
    ensure => present,
    source =>
    'puppet:///modules/service_diffusion_sympa/systemd-unitfiles/sympa-task_manager.service'
  }
  exec {'Rechargement SystemD':
    path        => '/bin',
    command     => 'systemctl daemon-reload',
    refreshonly => true,
    logoutput   => 'on_failure',
    subscribe   => File[ '/lib/systemd/system/sympa.service',
                        '/lib/systemd/system/sympa-archived.service',
                        '/lib/systemd/system/sympa-bounced.service',
                        '/lib/systemd/system/sympa-bulk.service',
                        '/lib/systemd/system/sympa-task_manager.service']
  }
  ## Activation du service
  service {'sympa':
    ensure  => 'running',
    require => [ File['/lib/systemd/system/sympa.service',
                      '/lib/systemd/system/sympa-archived.service',
                      '/lib/systemd/system/sympa-bounced.service',
                      '/lib/systemd/system/sympa-bulk.service',
                      '/lib/systemd/system/sympa-task_manager.service'],
                 Exec['Health-Check'] ],
  }

  # Fichiers SSL
  file {"Clé ${basename}":
    ensure => present,
    path   => "/etc/ssl/private/${basename}.key",
    source => "puppet:///modules/service_diffusion_sympa/${basename}.key",
  }
  file {"Certificat ${basename}":
    path   => "/etc/ssl/certs/${basename}.crt",
    source => "puppet:///modules/service_diffusion_sympa/${basename}.crt",
  }
  file {"Clé www.${basename}":
    ensure => present,
    path   => "/etc/ssl/private/www.${basename}.key",
    source => "puppet:///modules/service_diffusion_sympa/www.${basename}.key",
  }
  file {"Certificat www.${basename}":
    path   => "/etc/ssl/certs/www.${basename}.crt",
    source => "puppet:///modules/service_diffusion_sympa/www.${basename}.crt",
  }  

  ### Serveur web
  # Installation Apache => Classe apache !
  class {'::apache':
    # Documentation : https://forge.puppetlabs.com/puppetlabs/apache
    default_mods        => false,
    default_confd_files => false,
    serveradmin         => "listmaster@${domain}",
    server_signature    => 'Off',
    server_tokens       => 'Prod',
    mpm_module          => 'worker',
    manage_user         => false,
    manage_group        => false,
    user                => 'sympa',
    group               => 'sympa',
  }
  # Redirection http://www
  apache::vhost {"http-www.${basename}":
    servername      => "www.${basename}",
    port            => '80',
    docroot         => '/var/www',
    redirect_dest   => "https://${basename}/",
    redirect_status => ['permanent'],
  }
  # Redirection https://www
  apache::vhost {"https-www.${basename}":
    require          => File["Clé www.${basename}",
                             "Certificat www.${basename}"],
    servername      => "www.${basename}",
    port            => '443',
    ssl             => true,
    ssl_key         => "/etc/ssl/private/www.${basename}.key",
    ssl_cert        => "/etc/ssl/certs/www.${basename}.crt",
    docroot         => '/var/www',
    redirect_dest   => "https://${basename}/",
    redirect_status => ['permanent'],
  }
  # Redirection http://
  apache::vhost {"http-${basename}":
    servername      => "${basename}",
    port            => '80',
    docroot         => '/var/www',
    redirect_dest   => "https://${basename}/",
    redirect_status => ['permanent'],
  }
  # Virtual host SSL
  class {'::apache::mod::dir': }
  class {'::apache::mod::fcgid':
    options => {
      'AddHandler'         => 'fcgid-script .fcgi',
      'FcgidBusyTimeout'   => '600',
      'FcgidIOTimeout'     => '600',
      'FcgidMaxRequestLen' => '134217728',
    }
  }
  file {'/var/lib/apache2/fcgid/sock/':
    owner => 'sympa',
    group => 'sympa',
  }
  apache::vhost {"https-${basename}":
    require          => File["Clé ${basename}",
                             "Certificat ${basename}"],
    servername       => "${basename}",
    port             => '443',
    ssl              => true,
    ssl_key          => "/etc/ssl/private/${basename}.key",
    ssl_cert         => "/etc/ssl/certs/${basename}.crt",
    docroot          => '/var/www',
    access_log_file  => "${basename}.access.log",
    options          => ['Indexes','FollowSymLinks','MultiViews'], # Default
    # value
    scriptaliases    => [ { alias => '/sympa',
                            path  => "${prefix}/bin/wwsympa.fcgi" },
                          { alias => '/sympasoap',
                            path  => "${prefix}/bin/sympa_soap_server.fcgi" }, ],
    aliases          => [ {
                          alias => '/static',
                          path  => "${prefix}/static_content",
                          }, ],
    fallbackresource => '/index.html',
    redirect_source  => ['/index.html'],
    redirect_dest    => ['/sympa'],
    redirect_status  => ['permanent'],
  }
  
  ## Icônes et couleur
  file {"${prefix}/static_content/icons/logo_sympa.png":
    ensure  => present,
    owner   => 'sympa',
    group   => 'sympa',
    mode    => '0644',
    require => Exec['Compilation : make install'],
    source  => "puppet:///modules/service_diffusion_sympa/logo-${domain}.png"}

  ## Config messagerie : cf https://forge.puppetlabs.com/camptocamp/postfix
  file {'/usr/share/augeas/lenses/dist/postfix_transport.aug':
    ensure => present,
    source => 'puppet:///modules/service_diffusion_sympa/postfix_transport.aug'
  }
  file {'/usr/share/augeas/lenses/dist/postfix_virtual.aug':
    ensure => present,
    source => 'puppet:///modules/service_diffusion_sympa/postfix_virtual.aug'
  }
  class {'::postfix':
    alias_maps          => 'hash:/etc/aliases,hash:/etc/mail/sympa_aliases',
    mta                 => true,
    smtp_listen         => 'all',
    relayhost           => 'smtp.unicaen.fr',
    use_sympa           => true,
    root_mail_recipient => "postmaster@${domain}"
  }
  include ::postfix
  file {'/etc/mail': ensure => directory }
  postfix::hash {'/etc/mail/sympa_aliases':
    ensure  => present,
    require => File['/etc/mail'],
    content => template('service_diffusion_sympa/sympa_aliases.erb'),
  }
  postfix::config {'relay_domains':
    ensure => present,
    value  => "${basename}",
  }
  postfix::config {'sympa_destination_recipient_limit':
    ensure => present,
    value  => '1',
  }
  postfix::config {'sympabounce_destination_recipient_limit':
    ensure => present,
    value  => '1',
  }
  postfix::config {'recipient_delimiter':
    ensure => present,
    value  => '+',
  }
  postfix::transport {"/^.*-owner\@${escaped_basename}$/":
    ensure      => present,
    destination => 'sympabounce',
    require     => File['/usr/share/augeas/lenses/dist/postfix_transport.aug',
                        '/usr/share/augeas/lenses/dist/postfix_virtual.aug']
  }
  postfix::transport {"/^.+(?<!-owner)\@${escaped_basename}$/":
    ensure      => present,
    destination => 'sympa',
    require     => File['/usr/share/augeas/lenses/dist/postfix_transport.aug',
                        '/usr/share/augeas/lenses/dist/postfix_virtual.aug']
  }
  
  ## Partiellement redondant avec /etc/aliases
  postfix::virtual {"/^(postmaster|abuse)\@${escaped_basename}$/":
    ensure      => present,
    destination => "\$1@${domain}",
    require     => File['/usr/share/augeas/lenses/dist/postfix_transport.aug',
                        '/usr/share/augeas/lenses/dist/postfix_virtual.aug']
  }
  postfix::virtual {"/^(listmaster|sympa-request|sympa-owner)\@${escaped_basename}$/":
    ensure      => present,
    destination => "listmaster@${domain}",
    require     => File['/usr/share/augeas/lenses/dist/postfix_transport.aug',
                        '/usr/share/augeas/lenses/dist/postfix_virtual.aug']
  }

  ## Configuration logs
  file {'/etc/syslog-ng/conf.d/sympa.conf':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/service_diffusion_sympa/syslog-ng.sympa.conf',
  }
  file {'/etc/logrotate.d/mail':
    owner  => root,
    group  => root,
    mode   => '0644',
    source => 'puppet:///modules/service_diffusion_sympa/logrotate.d_mail',
  }
  file {'/etc/logrotate.d/sympa':
    owner  => root,
    group  => root,
    mode   => '0644',
    source => 'puppet:///modules/service_diffusion_sympa/logrotate.d_sympa',
  }

  ## Spécifique unicaen.fr
  if $domain == 'unicaen' {
    # Catégories de listes
    file {"${prefix}/etc/topics.conf":
      ensure  => present,
      require => Exec['Compilation : make install'],
      owner   => 'sympa',
      group   => 'sympa',
      mode    => '0644',
      source  => 'puppet:///modules/service_diffusion_sympa/topics.conf',
    }
    # ☛ TODO Scénarios
    # ☛ TODO Modèles de listes
    # ☛ TODO create_list_templates.tt2
    # ☛ TODO Autres modèles TT2 (/web/ et /mail/)
    # ☛ TODO Tâche Cron pour sympa.pl --reload_list_config
  }
}

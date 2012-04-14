class graphite {

  include supervisor

  package {
    [python-pip, gcc, python-dev]:
    ensure => installed
  }

  # Currently, pip freeze seems unable to discover the carbon and graphite-web 
  # packages when already installed, so they are re-installed everytime (though 
  # that is then very quick).
  package { 
    ['whisper', 'carbon', 'graphite-web']:
      ensure => installed,
      provider => pip,
      require => Package[python-pip]
  }
  
  ###########################################################################
  # Install the graphite-web interface
  
  package {
    [python-cairo]:
    ensure => installed
  }
  package {
    [Twisted, 'django==1.2', 'django-tagging']:
    ensure => installed,
    provider => pip,
    require => Package[gcc]
  }
  
  file { [ "/opt/graphite/storage", "/opt/graphite/storage/whisper" ]:
    owner => "www-data",
    subscribe => Package["graphite-web"],
    mode => "0775",
  }
  
  file { "/opt/graphite/webapp/graphite/local_settings.py" :
    source => "puppet:///modules/graphite/local_settings.py",
    ensure => present,
    require => File["/opt/graphite/storage"]
  }
  
  exec { "initialize-db":
    command => "export PYTHONPATH=/opt/graphite/webapp && cd /opt/graphite/webapp/graphite/ && python manage.py syncdb --noinput",
    provider => shell,
    subscribe => Package["graphite-web"],
    refreshonly => true,
    user => 'www-data',
    logoutput => true,
    creates => '/opt/graphite/storage/graphite.db'
  }
  
  exec { "set-password":
    command => "export PYTHONPATH=/opt/graphite/webapp && cd /opt/graphite/webapp/graphite/ && python manage.py createsuperuser --username michael --email michael@elsdoerfer.com --noinput",
    provider => shell,
    require => Exec["initialize-db"],
    user => 'www-data',
  }
  
  package { "nginx-full": ensure => installed }
  package { "uwsgi": ensure => installed, provider => pip }
  
  supervisor::service {
    'uwsgi-graphite':
      ensure      => running,
      enable      => true,
      command     => "/usr/local/bin/uwsgi --socket 127.0.0.1:3031 --master --limit-as 512 --chdir=/opt/graphite/webapp --env DJANGO_SETTINGS_MODULE=graphite.settings --module='django.core.handlers.wsgi:WSGIHandler()'",
      require     => [ Package[graphite-web], Package[uwsgi] ],
  }
  
  service { 
      nginx: ensure => running,
      subscribe => File['/etc/nginx/sites-enabled/graphite']
  }

  file { "/etc/nginx/sites-enabled/graphite" :
    source => "puppet:///modules/graphite/graphite.nginx",
    ensure => present,
    subscribe => Package["nginx-full"],
  }  
  
  ###########################################################################
  # Install the carbon daemon
  
  file { "/opt/graphite/conf/carbon.conf" :
    source => "puppet:///modules/graphite/carbon.conf",
    ensure => present,
    subscribe => Package[carbon],
  }
  
  file { "/opt/graphite/conf/storage-schemas.conf" :
    source => "puppet:///modules/graphite/storage-schemas.conf",
    ensure => present,
    subscribe => Package[carbon],
  }  

  supervisor::service {
    'carbon':
      ensure      => running,
      enable      => true,
      command     => 'python /opt/graphite/bin/carbon-cache.py --debug start',
      subscribe   => File['/opt/graphite/conf/carbon.conf', '/opt/graphite/conf/storage-schemas.conf'],
  }
  
  
  ###########################################################################
  # Install statsite (Python version of statsd)
  
  package { statsite: provider => pip, ensure => installed }
  
  file { "/etc/statsite.conf" :
    source => "puppet:///modules/graphite/statsite.conf",
    ensure => present,
    subscribe => Package[statsite],
  }    
  
  supervisor::service {
    'statsite':
      ensure      => running,
      enable      => true,
      command     => '/usr/local/bin/statsite -c /etc/statsite.conf',
      require     => File['/etc/statsite.conf'],
  }  
  
}




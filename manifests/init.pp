# == Class: jenkins_windows_agent
#
# Module to install the jenkins agent on Windows platform using the swarm_client jar
#
# === Parameters
#
#  == Most params are self explanatory
#
# [*client_source*]
#   File source for jenkins slave jar. Default pulls from https://repo.jenkins-ci.org
#
# [*version*]
#   The version of the swarm client code. Default is '3.3'. This should match the plugin version on the master
#
# [*verify_peer*]
#   Boolean: defaults to false
#   Used in remote_file type to control whether or not to require SSL verification of the the remote server
#
# [*swarm_labels*]
#   Labels to associate this agent with.  (Space-delimited string)
#   Defaults to 'windows'
#
# [*disable_clients_unique_id*]
#   Maps to -disableClientsUniqueId in https://plugins.jenkins.io/swarm/
#   Defaults to false
#
# [*disable_ssl_verification*]
#   Maps to -disableSslVerification in https://plugins.jenkins.io/swarm/
#   Defaults to true (for historical reasons)
#
# [*swarm_client_args*]
#   Any other valid args to swarm client not covered by the above, see https://plugins.jenkins.io/swarm/
#   Example: '-maxRetryInterval 4 -deleteExistingClients'
#   Defaults to empty string
#
# [*jenkins_master_user*]
#   The user account needed to authenticate agains the Jenkins Master machine
#   Defaults to jenkins
#
# [*jenkins_master_pass*]
#   The password for jenkins_master_user
#   Defaults to pass123
#
# [*service_name*]
#   Specifies the name of the Windows service
#   Defaults to Jenkins_Agent
#
# [*service_user*]
#   Specifies the user account to run the service as
#   Defaults to LocalSystem
#
# [*service_pass*]
#   The password of the service_user
#   Defaults to undefined
#   If service_user is changed from default, service_pass must also be specified
#
# [*service_interactive*]
#   Allow service to interact with desktop
#   Defaults to false
#
# [*create_user*]
#   Boolean to control whether the service_user should be created
#   Defaults to false; assumption is made that an AD service account will be used
#
#
class jenkins_windows_agent (
  $client_source             = $::jenkins_windows_agent::params::client_source,
  $version                   = $::jenkins_windows_agent::params::version,
  $verify_peer               = $::jenkins_windows_agent::params::verify_peer,
  $swarm_mode                = $::jenkins_windows_agent::params::swarm_mode,
  $swarm_executors           = $::jenkins_windows_agent::params::swarm_executors,
  $swarm_labels              = $::jenkins_windows_agent::params::swarm_labels,
  $disable_clients_unique_id = $::jenkins_windows_agent::params::disable_clients_unique_id,
  $disable_ssl_verification  = $::jenkins_windows_agent::params::disable_ssl_verification,
  $swarm_client_args         = $::jenkins_windows_agent::params::swarm_client_args,
  $agent_drive               = $::jenkins_windows_agent::params::agent_drive,
  $agent_home                = $::jenkins_windows_agent::params::agent_home,
  $jenkins_dirs              = $::jenkins_windows_agent::params::jenkins_dirs,
  $jenkins_master_url        = $::jenkins_windows_agent::params::jenkins_master_url,
  $jenkins_master_user       = $::jenkins_windows_agent::params::jenkins_master_user,
  $jenkins_master_pass       = $::jenkins_windows_agent::params::jenkins_master_pass,
  $service_name              = $::jenkins_windows_agent::params::service_name,
  $service_user              = $::jenkins_windows_agent::params::service_user,
  $service_pass              = $::jenkins_windows_agent::params::service_pass,
  $service_interactive       = $::jenkins_windows_agent::params::service_interactive,
  $create_user               = $::jenkins_windows_agent::params::create_user,
  $jdk                       = $::jenkins_windows_agent::params::jdk,
  $jdk_choco_version         = $::jenkins_windows_agent::params::jdk_choco_version,
  $java                      = $::jenkins_windows_agent::params::java,
) inherits ::jenkins_windows_agent::params {

  # versioncmp function returns -1 if 2.2 is less than $version
  # version 2.2 is last version to contain the portion '-jar-with-dependencies'
  # as part of the jar file name
  if versioncmp('2.2', $version) < 0 {
    $client_jar = "swarm-client-${version}.jar"
  } else {
    $client_jar = "swarm-client-${version}-jar-with-dependencies.jar"
  }

  $client_url = $client_source ? {
    'repo.jenkins-ci.org' => "https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${version}/",
    default               => $client_source,
  }

  #if service_user is set and service_interactive is true; fail
  if ($service_user != 'LocalSystem') and ($service_interactive) {
    fail 'A service may only be configured as interactive if it runs under the LocalSystem account'
  }
  #if service_user is set and service_pass is set to non undef value; fail (When used as a boolean, undef is false)
  if ($service_user != 'LocalSystem') and (!$service_pass) {
    fail 'A password must be set when specifying a service user account'
  }
  if $::facts['os']['name'] != 'windows' {
    fail "This modules is not supported on ${::facts['os']['name']}"
  }

  # 'choco install nssm' via Puppet fails; use counsyl/windows::nssm
  include windows::nssm

  windows_env { 'nssm_install_env':
    ensure    => present,
    variable  => 'PATH',
    mergemode => 'append',
    value     => 'C:\Program Files\nssm-2.24\win64',
  }

  package { $jdk:
    ensure   => $jdk_choco_version,
    provider => 'chocolatey',
    before   => Nssm::Install[$service_name],
  }

  remote_file { $client_jar:
    ensure      => present,
    verify_peer => $verify_peer,
    path        => "${agent_drive}${agent_home}${client_jar}",
    source      => "${client_url}${client_jar}",
    require     => Jenkins_windows_agent::Create_dir[$jenkins_dirs],
  }

  $jenkins_dirs.each |Integer $index, String $dir| {
    jenkins_windows_agent::create_dir { $dir:
      drive  => $agent_drive,
      path   => $dir,
      before => Nssm::Install[$service_name],
    }
  }

  # Install the service
  nssm::install { $service_name:
    ensure       => present,
    program      => $java,
    service_name => $service_name,
    require      => Class['windows::nssm'],
  }

  # generate swarm client args
  $client_arg_unique_id  = $disable_clients_unique_id ? { true => '-disableClientsUniqueId', default => ''}
  $client_arg_ssl_verify = $disable_ssl_verification  ? { true => '-disableSslVerification', default => ''}
  $client_args = "${client_arg_unique_id} ${client_arg_ssl_verify} ${swarm_client_args}"


  file {"${agent_drive}${agent_home}labels.txt":
    content => $swarm_labels,
  }

  # Service Management
  nssm::set { $service_name:
    service_user        => $service_user,
    service_pass        => $service_pass,
    service_interactive => $service_interactive,
    create_user         => $create_user,
    app_parameters      => "-jar ${agent_drive}${agent_home}${client_jar} -mode ${swarm_mode} -executors ${swarm_executors} -username ${jenkins_master_user} -password ${jenkins_master_pass} -master ${jenkins_master_url} -labelsFile ${agent_drive}${agent_home}labels.txt -fsroot ${agent_drive}${agent_home} ${client_args}",
    require             => Nssm::Install[$service_name],
    notify              => Service[$service_name],
  }

  service { $service_name:
    ensure  => running,
    enable  => true,
    require => Nssm::Set[$service_name],
  }

}

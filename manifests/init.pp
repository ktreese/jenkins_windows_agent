# == Class: jenkins_windows_agent
#
# Module to install the jenkins agent on Windows platform using the swarm_client jar
#
# === Parameters
#
#  == Most params are self explanatory
#
# [*client_url*]
#   Url to download the client jar from, without the filename.
#
# [*client_jar*]
#   Filename of the client jar.
#
# [*version*]
#   The version of the swarm client code. Default is '1.22'. This should match the plugin version on the master
#
# [*verify_peer*]
#   Boolean: defaults to false
#   Used in remote_file type to control whether or not to require SSL verification of the the remote server
#
# [*swarm_labels*]
#   Labels to associate this agent with
#   Defaults to 'windows'
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
  $client_url          = $::jenkins_windows_agent::params::client_url,
  $client_jar          = $::jenkins_windows_agent::params::client_jar,
  $version             = $::jenkins_windows_agent::params::version,
  $verify_peer         = $::jenkins_windows_agent::params::verify_peer,
  $swarm_mode          = $::jenkins_windows_agent::params::swarm_mode,
  $swarm_executors     = $::jenkins_windows_agent::params::swarm_executors,
  $swarm_labels        = $::jenkins_windows_agent::params::swarm_labels,
  $agent_drive         = $::jenkins_windows_agent::params::agent_drive,
  $agent_home          = $::jenkins_windows_agent::params::agent_home,
  $jenkins_dirs        = $::jenkins_windows_agent::params::jenkins_dirs,
  $jenkins_master_url  = $::jenkins_windows_agent::params::jenkins_master_url,
  $jenkins_master_user = $::jenkins_windows_agent::params::jenkins_master_user,
  $jenkins_master_pass = $::jenkins_windows_agent::params::jenkins_master_pass,
  $service_name        = $::jenkins_windows_agent::params::service_name,
  $service_user        = $::jenkins_windows_agent::params::service_user,
  $service_pass        = $::jenkins_windows_agent::params::service_pass,
  $service_interactive = $::jenkins_windows_agent::params::service_interactive,
  $service_std_out     = $::jenkins_windows_agent::params::service_std_out,
  $service_err_out     = $::jenkins_windows_agent::params::service_err_out,
  $create_user         = $::jenkins_windows_agent::params::create_user,
  $install_java        = $::jenkins_windows_agent::params::install_java,
  $java_exe_path       = $::jenkins_windows_agent::params::java_exe_path,
  $java_pkg_name       = $::jenkins_windows_agent::params::java_pkg_name,
  $java_pkg_source     = $::jenkins_windows_agent::params::java_pkg_source,
  $install_nssm        = $::jenkins_windows_agent::params::install_nssm,
  $nssm_pkg_name       = $::jenkins_windows_agent::params::nssm_pkg_name,
  $nssm_pkg_source     = $::jenkins_windows_agent::params::nssm_pkg_source,
) inherits ::jenkins_windows_agent::params {

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

  if $install_nssm {
    ensure_resource(
      'package',
      $nssm_pkg_name, {
        ensure   => present,
        source   => $nssm_pkg_source,
        provider => 'chocolatey',
        before   => Nssm::Install[$service_name],
      }
    )

  }

  if $install_java {
    ensure_resource(
      'package',
      $java_pkg_name, {
        ensure   => present,
        source   => $java_pkg_source,
        provider => 'chocolatey',
        before   => Nssm::Install[$service_name],
      }
    )
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
    program      => $java_exe_path,
    service_name => $service_name,
    require      => [
      Package[$nssm_pkg_name],
      Package[$java_pkg_name],
    ],
  }

  # Service Management
  $swarm_labels_str = join($swarm_labels, " ")
  $app_parameters = @("END_APP_PARAMETERS"/$L)
    -jar ${agent_drive}${agent_home}${client_jar} \
    -mode ${swarm_mode} \
    -executors ${swarm_executors} \
    -username ${jenkins_master_user} \
    -password ${jenkins_master_pass} \
    -master ${jenkins_master_url} \
    -labels "${swarm_labels_str}" \
    -fsroot ${agent_drive}${agent_home} \
    -showHostName -name ${::fqdn} \
    | END_APP_PARAMETERS

  nssm::set { $service_name:
    service_user        => $service_user,
    service_pass        => $service_pass,
    service_interactive => $service_interactive,
    create_user         => $create_user,
    app_std_out         => $service_std_out,
    app_err_out         => $service_err_out,
    app_parameters      => $app_parameters,
    require             => [
      Nssm::Install[$service_name],
      Package[$nssm_pkg_name],
      Package[$java_pkg_name],
    ],
    notify              => Service[$service_name],
  }

  service { $service_name:
    ensure  => running,
    enable  => true,
    require => [
      Nssm::Install[$service_name],
      Package[$nssm_pkg_name],
      Package[$java_pkg_name],
    ],
  }

}

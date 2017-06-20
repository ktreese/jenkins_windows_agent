# Class: jenkins_windows_agent::params
#
#
class jenkins_windows_agent::params {
  $client_source            = 'repo.jenkins-ci.org'
  $version                  = '3.3'
  $verify_peer              = false
  $swarm_mode               = 'exclusive'
  $swarm_executors          = '8'
  $swarm_labels             = 'windows'
  $disable_ssl_verification = '-disable_ssl_verification'
  $agent_drive              = 'C:'
  $agent_home               = '/opt/ci/jenkins/'
  $jenkins_dirs             = ['/opt/ci/jenkins/', '/opt/ci/jenkins/workspace/', '/tmp']
  $jenkins_master_url       = 'http://myjenkinsmaster.localhost:8080'
  $jenkins_master_user      = 'jenkins'
  $jenkins_master_pass      = 'pass123'
  $service_name             = 'Jenkins_Agent'
  $service_user             = 'LocalSystem'
  $service_pass             = undef
  $service_interactive      = false
  $create_user              = false
  $jdk                      = 'jdk8'
  $jdk_choco_version        = '8.0.131'
  $java                     = '$ENV:JAVA_HOME\bin\java.exe'
}

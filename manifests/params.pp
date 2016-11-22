# Class: jenkins_windows_agent::params
#
#
class jenkins_windows_agent::params {
  $version      = '1.22'
  $client_url = $client_source ? {
    undef   => "https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${version}/",
    default => $client_source,
  }
  $client_url          = "https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${version}/""
  $client_jar          = "swarm-client-${version}-jar-with-dependencies.jar"
  $verify_peer         = false
  $swarm_mode          = 'exclusive'
  $swarm_executors     = '8'
  $swarm_labels        = 'windows'
  $agent_drive         = 'C:'
  $agent_home          = '/opt/ci/jenkins/'
  $jenkins_dirs        = ['/opt/ci/jenkins/', '/opt/ci/jenkins/workspace/', '/tmp']
  $jenkins_master_url  = 'http://myjenkinsmaster.localhost:8080'
  $jenkins_master_user = 'jenkins'
  $jenkins_master_pass = 'pass123'
  $service_name        = 'Jenkins_Agent'
  $service_user        = 'LocalSystem'
  $service_pass        = undef
  $service_interactive = false
  $create_user         = false
  $java                = 'C:\Program Files\Java\jdk1.7.0_79\bin\java.exe'
}

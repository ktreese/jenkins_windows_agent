# Class: jenkins_windows_agent::params
#
#
class jenkins_windows_agent::params {
  $client_url          = 'https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/2.2/'
  $client_jar          = 'swarm-client-1.22-jar-with-dependencies.jar'
  $version             = '1.22'
  $verify_peer         = false
  $swarm_mode          = 'exclusive'
  $swarm_executors     = '8'
  $swarm_labels        = 'windows'
  $agent_drive         = 'C:'
  $agent_home          = '/opt/ci/jenkins/'
  $jenkins_dirs        = [
    '/opt/ci/jenkins/',
    '/opt/ci/jenkins/workspace/',
    '/tmp',
  ]
  $jenkins_master_url  = 'http://myjenkinsmaster.localhost:8080'
  $jenkins_master_user = 'jenkins'
  $jenkins_master_pass = 'pass123'
  $service_name        = 'Jenkins_Agent'
  $service_user        = 'LocalSystem'
  $service_pass        = undef
  $service_interactive = false
  $service_std_out     = 'C:\opt\ci\jenkins\jenkins.log'
  $service_err_out     = 'C:\opt\ci\jenkins\jenkins_error.log'
  $create_user         = false
  $install_java        = true
  $java_exe_path       = 'C:\\Program Files\\Java\\jre1.8.0_111\\bin\\java.exe'
  $java_pkg_name       = 'javaruntime'
  $java_pkg_source     = undef
  $install_nssm        = true
  $nssm_pkg_name       = 'nssm'
  $nssm_pkg_source     = undef
}

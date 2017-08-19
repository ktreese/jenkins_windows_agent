# jenkins_windows_agent

## Table of Contents

1. [Overview](#overview)
2. [Module Dependencies - What are the dependencies](#module-dependencies)
3. [Module Description - What the module does and why it is useful](#module-description)
4. [Classifcation Setup - The basics of getting started with jenkins_windows_agent](#classification-setup)

  - [What the jenkins_agent module affects](#what-the-jenkins_agent-module-affects)
  - [Setup requirements](#setup-requirements)

## Overview

This module will deploy the Jenkins Agent on Windows systems via the swarm jar and run it as a windows service using NSSM.

## Module Dependencies

Please review the [Dependencies](https://forge.puppet.com/ktreese/jenkins_windows_agent/dependencies) to ensure you have all that is required in order for this module to function properly.

## Module Description

The Windows Jenkins Agent will be deployed with the following defaults:

- swarm-client-3.3.jar ([JENKINS-42138](https://issues.jenkins-ci.org/browse/JENKINS-42138) indicates this jar contains the dependencies)
- mode: exclusive
- executors: 8
- labels: windows
- Agent Home: C:\opt\ci\jenkins
- Agent Workspace: C:\opt\ci\jenkins\workspace
- Jenkins Master: <http://myjenkinsmaster.localhost:8080>
- java: latest choco jdk8 package
- `disableSslVerification` swarm option enabled (override via hiera to undef if not needed)
- service account: `LocalSystem`

Puppet will create a windows service `Jenkins_Agent` and set it to run as the `LocalSystem` account

Any of the above defaults can be overridden via hiera as described in [Setup Requirements](#setup-requirements).

If overriding the service account, the credentials for that user may be stored in an encrypted format in hiera via eyaml.

## Classification Setup

This module includes a single class:

`include jenkins_windows_agent`

At a minimum, the `jenkins_master_url`, `jenkins_master_user`, and `jenkins_master_pass` variables should be overridden via hiera, Puppet Console, or inside of a resource like declaration:

```
class { 'jenkins_windows_agent':
  jenkins_master_url  => 'http://your_jenkins_master_url:8080',
  jenkins_master_user => 'your_jenkins_master_user',
  jenkins_master_pass => 'your_jenkins_master_pass',
}
```

### What the jenkins_agent module affects

#### List of things that the module will alter:

```
 - Installs jdk8
 - Installs NSSM - the Non-Sucking Service Manager
 - Creates C:/tmp; C:/opt/ci/jenkins; C:/opt/ci/jenkins/workspace
 - Creates Jenkins_Agent service to run as LocalSystem via NSSM
 - Sets arguments / parameters for Jenkins_Agent service via NSSM
 - Manages Jenkins_Agent service
```

### Setup Requirements

Please review the [Module Dependencies](#module-dependencies) section.

Override default values in the Puppet Console, or namespace the key/value pairs appropriately in the desired yaml hieradata file. At minimum, you'll need to override the `jenkins_master_url`, `jenkins_master_user`, and `jenkins_master_pass` variables to your environments specifications.

For example, to override these variables via hiera:

```
jenkins_windows_agent::jenkins_master_url: http://your_jenkins_master_url:8080
jenkins_windows_agent::jenkins_master_user: jenkins
jenkins_windows_agent::jenkins_master_pass: mypassword
```

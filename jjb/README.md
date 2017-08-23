# [Jenkins Job Builder](http://docs.openstack.org/infra/jenkins-job-builder/) config for CADETS CI jobs

Setup:
- Install Jenkins Job Builder form ports/pkg:`devel/py-jenkins-job-builder` or source
- `cp jenkins_jobs.ini.sample jenkins_jobs.ini`
- Edit `jenkins_jobs.ini` for your credenticals of https://allendale.engr.mun.ca/jenkins/
  (at https://allendale.engr.mun.ca/jenkins/me/configure -> "show api token")

Update jenkins jobs:
`make`

pipeline {
  agent any
  stages {
    stage('start new build in dev-{service}') {
      steps {
        script {
          try {
            echo "ssh script execute"
            sshagent (credentials: ['stockey']) {
              sh "ssh -o StrictHostKeyChecking=no ubuntu@15.164.240.191 '/home/ubuntu/server/config.sh'"
            }
          } catch (err) {
            mattermostSend(
              color: "danger",
              message: "[config run fail]\nJob name: ${env.JOB_NAME} in ${env.NODE_NAME} #${currentBuild.number}\n cause: ${err.cause}\n message: ${err.message}"
            )
            err.printStackTrace()
          }
        }
      }
    }
  }
}
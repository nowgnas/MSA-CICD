pipeline {
  agent any
  stages {
    stage('run discovery docker compose via ssh') {
      steps {
        script {
          try {
            echo "ssh script execute"
            sshagent (credentials: ['stockey']) {
              sh "ssh -o StrictHostKeyChecking=no ubuntu@15.164.240.191 '/home/ubuntu/server/discovery.sh'"
            }
          } catch (err) {
            mattermostSend(
              color: "danger",
              message: "[discovery run fail]\nJob name: ${env.JOB_NAME} in ${env.NODE_NAME} #${currentBuild.number}\n cause: ${err.cause}\n message: ${err.message}"
            )
            err.printStackTrace()
          }
        }
      }
    }
  }
}
pipeline {
  environment {
    registry = 'registry-intl.ap-southeast-1.aliyuncs.com/swmeng/flutter-ion-conference-'
    registryCredential = 'aliclouddocker'
    DOCKER_CREDENTIALS = credentials('aliclouddocker')
    SERVER_IP = credentials('ALICLOUD_ECS_HK_IP')
  }
  agent any
  stages {
    stage('Build Images') {
      steps {
        script {
          clientImage = docker.build(registry + 'client', './')
        }
      }
    }
    stage('Push Images') {
      steps {
        script {
          docker.withRegistry('https://registry-intl.ap-southeast-1.aliyuncs.com', registryCredential ) {
            clientImage.push("${env.BUILD_NUMBER}")
            clientImage.push('latest')
          }
        }
      }
    }
    stage('Remove Unused Docker Image') {
      steps {
        sh "docker rmi ${registry}client"
      }
    }
    stage('Deploy Images') {
      steps {
        sshagent(credentials:['ALICLOUD_HONG_KONG_SERVER_KEY']) {
            sh ('scp -o StrictHostKeyChecking=no -r ./deploy root@$SERVER_IP:/root/flutter-ion-conference')
            sh ('ssh -o StrictHostKeyChecking=no root@$SERVER_IP \"export BUILD_NUMBER=$BUILD_NUMBER && docker login -u $DOCKER_CREDENTIALS_USR -p $DOCKER_CREDENTIALS_PSW registry-intl.ap-southeast-1.aliyuncs.com && cd /root/flutter-ion-conference/deploy && sh ./deploy.sh\"')
          }
      }
    }
  }
}
pipeline {
    agent any
    parameters {
        booleanParam(name: 'Enable_lint', defaultValue: false, description: 'Enable linting procedure')
        booleanParam(name: 'Enable_test', defaultValue: true, description: 'Enable unit testing')
        booleanParam(name: 'Enable_build', defaultValue: true, description: 'Enable docker container build')
    }
    stages {

        stage('linter') {
            when { expression {params.Enable_lint == true }}
            steps {
                    node("linter") {
                        git 'https://github.com/minamijoyo/myaws.git'
                        container('linter') {
                        sh 'golangci-lint version  && golangci-lint run'
                        }
                    }
            }
        }


        stage('tester') {
            when { expression {params.Enable_test == true }}
            steps {
                    node("tester") {
                        git 'https://github.com/minamijoyo/myaws.git'
                        container('go') {
                            sh 'apk add --update alpine-sdk'
                            sh 'make test'
                        }
                    }
            }
        }



        stage('build-container') {
            when { expression {params.Enable_build == true }}
            steps {
                    node("docker-dind") {
                        git 'https://github.com/minamijoyo/myaws.git'
                        container('docker') {
                        sh 'docker version  && docker build -t myaws .'
                    }
                  }
            }
        }
    }
}
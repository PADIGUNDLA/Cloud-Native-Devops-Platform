pipeline {
    agent {
        label 'docker-agent'
    }

    stages {
        stage('Test Docker') {
            steps {
                container('docker') {
                    sh '''
                        echo "Docker version:"
                        docker version

                        echo "Docker info:"
                        docker info
                    '''
                }
            }
        }
    }
}
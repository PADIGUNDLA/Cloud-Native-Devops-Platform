pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'padigundla/devops-dashboard'
        DOCKER_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                '''
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh '''
                    trivy image --exit-code 0 --severity HIGH,CRITICAL \
                    ${DOCKER_IMAGE}:${DOCKER_TAG}
                '''
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login \
                        -u "$DOCKER_USERNAME" --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }

        success {
            echo '✅ CI pipeline completed successfully!'
        }

        failure {
            echo '❌ CI pipeline failed. Check the console output.'
        }
    }
}
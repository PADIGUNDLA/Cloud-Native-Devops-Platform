pipeline {
    agent {
        label 'docker-agent'
    }

    environment {
        IMAGE_NAME = 'padigundla/devops-dashboard'
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Source code checked out by Jenkins'
            }
        }

        stage('Docker Build') {
            steps {
                container('docker') {
                    sh '''
                        echo "Waiting for Docker daemon..."

                        for i in $(seq 1 30); do
                            if docker info >/dev/null 2>&1; then
                                echo "Docker daemon is ready!"
                                break
                            fi

                            echo "Docker daemon not ready yet... attempt $i/30"
                            sleep 2
                        done

                        docker info

                        echo "Building Docker image..."
                        docker build \
                          -t ${IMAGE_NAME}:${IMAGE_TAG} \
                          -t ${IMAGE_NAME}:latest \
                          .
                    '''
                }
            }
        }

        stage('Docker Image Test') {
            steps {
                container('docker') {
                    sh '''
                        echo "Docker images:"
                        docker images ${IMAGE_NAME}

                        echo "Testing image..."
                        docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} \
                          sh -c "echo Container started successfully"
                    '''
                }
            }
        }

        stage('Docker Push') {
            steps {
                container('docker') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-credentials',
                            usernameVariable: 'DOCKERHUB_USERNAME',
                            passwordVariable: 'DOCKERHUB_TOKEN'
                        )
                    ]) {
                        sh '''
                            echo "$DOCKERHUB_TOKEN" | docker login \
                              -u "$DOCKERHUB_USERNAME" \
                              --password-stdin

                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${IMAGE_NAME}:latest

                            docker logout
                        '''
                    }
                }
            }
        }
    }
}

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

                        READY=false

                        for i in $(seq 1 30); do
                            if docker info >/dev/null 2>&1; then
                                echo "Docker daemon is ready!"
                                READY=true
                                break
                            fi

                            echo "Docker daemon not ready yet... attempt $i/30"
                            sleep 2
                        done

                        if [ "$READY" != "true" ]; then
                            echo "ERROR: Docker daemon did not become ready."
                            exit 1
                        fi

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

        stage('Docker Hub Connectivity Test') {
            steps {
                container('docker') {
                    sh '''
                        echo "===== Docker Hub Authentication Diagnostic ====="

                        echo ""
                        echo "1. Registry endpoint:"

                        wget -S -O /dev/null \
                          https://registry-1.docker.io/v2/ \
                          2>&1 || true

                        echo ""
                        echo "2. Authentication service:"

                        wget -S -O /dev/null \
                          "https://auth.docker.io/token?service=registry.docker.io" \
                          2>&1 || true

                        echo ""
                        echo "3. Docker daemon environment:"

                        env | grep -E 'DOCKER|HTTP_PROXY|HTTPS_PROXY|NO_PROXY' || true

                        echo ""
                        echo "4. Docker daemon info:"

                        docker info

                        echo ""
                        echo "5. Docker daemon version:"

                        docker version

                        echo ""
                        echo "===== End Diagnostic ====="
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
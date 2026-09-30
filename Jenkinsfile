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

        stage('Docker Hub Credential Test') {
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
                            echo "===== Docker Hub Credential Test ====="

                            echo ""
                            echo "Testing Docker Hub login..."

                            set +e

                            printf '%s' "$DOCKERHUB_TOKEN" | \
                              docker login docker.io \
                              --username "$DOCKERHUB_USERNAME" \
                              --password-stdin

                            LOGIN_RESULT=$?

                            set -e

                            echo ""
                            echo "Docker login exit code: $LOGIN_RESULT"

                            if [ "$LOGIN_RESULT" -ne 0 ]; then
                                echo "ERROR: Docker Hub login failed."
                                exit 1
                            fi

                            echo "Docker Hub login succeeded."

                            echo ""
                            echo "Docker daemon version:"
                            docker version

                            echo ""
                            echo "Logging out..."
                            docker logout docker.io

                            echo ""
                            echo "===== End Credential Test ====="
                        '''
                    }
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
                            echo "Logging in to Docker Hub..."

                            printf '%s' "$DOCKERHUB_TOKEN" | \
                              docker login docker.io \
                              --username "$DOCKERHUB_USERNAME" \
                              --password-stdin

                            echo "Pushing image ${IMAGE_NAME}:${IMAGE_TAG}..."

                            docker push ${IMAGE_NAME}:${IMAGE_TAG}

                            echo "Pushing latest image..."

                            docker push ${IMAGE_NAME}:latest

                            echo "Logging out..."

                            docker logout docker.io
                        '''
                    }
                }
            }
        }
    }
}
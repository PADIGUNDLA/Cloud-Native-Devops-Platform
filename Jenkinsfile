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
                            echo "Testing Docker Hub authentication..."

                            wget \
                              --user="$DOCKERHUB_USERNAME" \
                              --password="$DOCKERHUB_TOKEN" \
                              -S \
                              -O /dev/null \
                              "https://auth.docker.io/token?service=registry.docker.io&scope=repository:padigundla/devops-dashboard:pull,push" \
                              2>&1

                            AUTH_RESULT=$?

                            echo ""
                            echo "Authentication test exit code: $AUTH_RESULT"

                            if [ "$AUTH_RESULT" -ne 0 ]; then
                                echo "ERROR: Docker Hub rejected the Jenkins credential."
                                exit 1
                            fi

                            echo "Docker Hub credential authentication succeeded."

                            echo ""
                            echo "Docker daemon version:"
                            docker version

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
                            echo "$DOCKERHUB_TOKEN" | docker login docker.io \
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
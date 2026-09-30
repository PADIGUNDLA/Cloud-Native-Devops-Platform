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
                        set -e

                        echo "===== Docker Build ====="

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

                        echo ""
                        echo "Docker version:"
                        docker version

                        echo ""
                        echo "Building Docker image..."

                        docker build \
                          -t ${IMAGE_NAME}:${IMAGE_TAG} \
                          -t ${IMAGE_NAME}:latest \
                          .

                        echo ""
                        echo "Docker image build completed successfully."
                    '''
                }
            }
        }

        stage('Docker Image Test') {
            steps {
                container('docker') {
                    sh '''
                        set -e

                        echo "===== Docker Image Test ====="

                        echo ""
                        echo "Docker images:"
                        docker images ${IMAGE_NAME}

                        echo ""
                        echo "Testing image..."

                        docker run --rm \
                          ${IMAGE_NAME}:${IMAGE_TAG} \
                          sh -c "echo Container started successfully"

                        echo ""
                        echo "Docker image test passed."
                    '''
                }
            }
        }

        stage('Docker Hub Login') {
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
                            set -e

                            echo "===== Docker Hub Login ====="

                            echo ""
                            echo "Docker Hub username:"
                            echo "$DOCKERHUB_USERNAME"

                            echo ""
                            echo "Logging in to Docker Hub..."

                            printf '%s' "$DOCKERHUB_TOKEN" | \
                                docker login \
                                --username "$DOCKERHUB_USERNAME" \
                                --password-stdin

                            echo ""
                            echo "Docker Hub authentication successful."
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
                            set -e

                            echo "===== Docker Hub Push ====="

                            echo ""
                            echo "Logging in to Docker Hub..."

                            printf '%s' "$DOCKERHUB_TOKEN" | \
                                docker login \
                                --username "$DOCKERHUB_USERNAME" \
                                --password-stdin

                            echo ""
                            echo "Docker Hub login successful."

                            echo ""
                            echo "Pushing image:"
                            echo "${IMAGE_NAME}:${IMAGE_TAG}"

                            docker push ${IMAGE_NAME}:${IMAGE_TAG}

                            echo ""
                            echo "Pushing latest image..."

                            docker push ${IMAGE_NAME}:latest

                            echo ""
                            echo "Docker images pushed successfully."

                            echo ""
                            echo "Logging out of Docker Hub..."

                            docker logout

                            echo ""
                            echo "===== Docker Hub Push Complete ====="
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            container('docker') {
                sh '''
                    echo "Cleaning temporary Docker authentication data..."

                    docker logout >/dev/null 2>&1 || true

                    rm -f "$HOME/.docker/config.json" 2>/dev/null || true

                    echo "Cleanup completed."
                '''
            }
        }

        success {
            echo '========================================'
            echo 'CI PIPELINE COMPLETED SUCCESSFULLY'
            echo '========================================'
            echo "Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
            echo "Docker image: ${IMAGE_NAME}:latest"
        }

        failure {
            echo '========================================'
            echo 'CI PIPELINE FAILED'
            echo '========================================'
            echo 'Check the failed stage above.'
        }
    }
}
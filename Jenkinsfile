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
                            echo "Installing curl..."

                            apk add --no-cache curl >/dev/null 2>&1

                            echo ""
                            echo "Creating authentication request..."

                            cat > /tmp/docker-auth.json <<EOF
{
  "identifier": "${DOCKERHUB_USERNAME}",
  "secret": "${DOCKERHUB_TOKEN}"
}
EOF

                            echo ""
                            echo "Testing Docker Hub PAT..."

                            HTTP_CODE=$(curl \
                              --silent \
                              --output /tmp/docker-auth-response.json \
                              --write-out "%{http_code}" \
                              --request POST \
                              --header "Accept: application/json" \
                              --header "Content-Type: application/json" \
                              --data-binary @/tmp/docker-auth.json \
                              https://hub.docker.com/v2/auth/token)

                            echo "Docker Hub authentication HTTP status: $HTTP_CODE"

                            rm -f /tmp/docker-auth.json
                            rm -f /tmp/docker-auth-response.json

                            if [ "$HTTP_CODE" != "200" ]; then
                                echo "ERROR: Docker Hub rejected the Jenkins credential."
                                exit 1
                            fi

                            echo "Docker Hub PAT authentication succeeded."

                            echo ""
                            echo "Testing Docker registry endpoint..."

                            wget -S -O /dev/null \
                              https://registry-1.docker.io/v2/ \
                              2>&1 || true

                            echo ""
                            echo "Docker daemon version:"

                            docker version

                            echo ""
                            echo "===== Credential Test Passed ====="
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

                            mkdir -p "$HOME/.docker"

                            AUTH=$(printf '%s:%s' \
                              "$DOCKERHUB_USERNAME" \
                              "$DOCKERHUB_TOKEN" | base64 | tr -d '\\n')

                            cat > "$HOME/.docker/config.json" <<EOF
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "$AUTH"
    },
    "https://registry-1.docker.io": {
      "auth": "$AUTH"
    },
    "docker.io": {
      "auth": "$AUTH"
    }
  }
}
EOF

                            chmod 600 "$HOME/.docker/config.json"

                            echo "Docker authentication configuration created."

                            echo ""
                            echo "Pushing image:"
                            echo "${IMAGE_NAME}:${IMAGE_TAG}"

                            docker push ${IMAGE_NAME}:${IMAGE_TAG}

                            echo ""
                            echo "Pushing latest image..."

                            docker push ${IMAGE_NAME}:latest

                            echo ""
                            echo "Docker images pushed successfully."

                            rm -f "$HOME/.docker/config.json"

                            echo ""
                            echo "Docker authentication configuration removed."

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
                    rm -f "$HOME/.docker/config.json" 2>/dev/null || true
                    rm -f /tmp/docker-auth.json 2>/dev/null || true
                    rm -f /tmp/docker-auth-response.json 2>/dev/null || true
                '''
            }
        }

        success {
            echo 'CI pipeline completed successfully.'
        }

        failure {
            echo 'CI pipeline failed. Check the stage logs above.'
        }
    }
}
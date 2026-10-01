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

                        echo ""
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

        stage('Trivy Security Scan') {
            steps {
                container('docker') {
                    sh '''
                        set -e

                        echo "===== Trivy Security Scan ====="

                        echo "Installing Trivy..."

                        apk add --no-cache curl

                        curl -sfL \
                          https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
                          | sh -s -- -b /usr/local/bin

                        echo ""
                        echo "Trivy version:"
                        trivy --version

                        echo ""
                        echo "Scanning Docker image:"
                        echo "${IMAGE_NAME}:${IMAGE_TAG}"

                        trivy image \
                          --severity HIGH,CRITICAL \
                          --exit-code 1 \
                          ${IMAGE_NAME}:${IMAGE_TAG}

                        echo ""
                        echo "Trivy security scan passed."
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

        stage('Helm Deploy') {
            steps {
                container('docker') {
                    sh '''
                        set -e

                        echo "===== Helm Deployment ====="

                        echo ""
                        echo "Installing required tools..."

                        apk add --no-cache curl tar

                        echo ""
                        echo "Installing Helm..."

                        curl -fsSL \
                          https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz \
                          -o /tmp/helm.tar.gz

                        tar -xzf /tmp/helm.tar.gz -C /tmp

                        mv /tmp/linux-amd64/helm /usr/local/bin/helm

                        chmod +x /usr/local/bin/helm

                        echo ""
                        echo "Helm version:"
                        helm version

                        echo ""
                        echo "Installing kubectl..."

                        curl -LO \
                          https://dl.k8s.io/release/v1.34.12/bin/linux/amd64/kubectl

                        chmod +x kubectl

                        mv kubectl /usr/local/bin/kubectl

                        echo ""
                        echo "kubectl version:"
                        kubectl version --client

                        echo ""
                        echo "Creating Kubernetes kubeconfig..."

                        export KUBECONFIG=/tmp/jenkins-kubeconfig

                        kubectl config set-cluster kubernetes \
                          --server=https://kubernetes.default.svc \
                          --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
                          --embed-certs=true

                        # Prevent the ServiceAccount token from appearing
                        # in Jenkins console output.
                        set +x

                        KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

                        kubectl config set-credentials jenkins-agent \
                          --token="$KUBE_TOKEN"

                        unset KUBE_TOKEN

                        set -x

                        kubectl config set-context jenkins-agent \
                          --cluster=kubernetes \
                          --user=jenkins-agent \
                          --namespace=default

                        kubectl config use-context jenkins-agent

                        echo ""
                        echo "Testing Kubernetes authentication..."

                        kubectl get deployment -n default

                        echo ""
                        echo "Current workspace:"
                        pwd

                        echo ""
                        echo "Workspace contents:"
                        ls -la

                        echo ""
                        echo "Checking Helm directory:"
                        ls -la helm || true

                        echo ""
                        echo "Checking Helm chart:"
                        ls -la helm/devops-dashboard || true

                        echo ""
                        echo "Deploying application with Helm..."

                        helm upgrade --install devops-dashboard-helm \
                          ./helm/devops-dashboard \
                          --namespace default \
                          --set image.tag=${BUILD_NUMBER}

                        echo ""
                        echo "Waiting for deployment rollout..."

                        kubectl rollout status \
                          deployment/devops-dashboard-helm \
                          --namespace default \
                          --timeout=180s

                        echo ""
                        echo "Helm deployment completed successfully."

                        echo ""
                        echo "Helm release:"

                        helm list --namespace default

                        echo ""
                        echo "Application status:"

                        kubectl get deployment,service,ingress \
                          -n default
                    '''
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
            echo 'CI/CD PIPELINE COMPLETED SUCCESSFULLY'
            echo '========================================'
            echo "Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
            echo "Docker image: ${IMAGE_NAME}:latest"
            echo 'Helm deployment completed.'
        }

        failure {
            echo '========================================'
            echo 'CI/CD PIPELINE FAILED'
            echo '========================================'
            echo 'Check the failed stage above.'
        }
    }
}
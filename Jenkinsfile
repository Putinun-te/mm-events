pipeline {
    agent any
    
    environment {
        // Docker Registry Configuration
        DOCKER_REGISTRY = 'docker.io'  // Change to your registry
        DOCKER_NAMESPACE = 'mmconcerts'  // Change to your namespace
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        
        // Image Names
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/concert-backend"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/concert-frontend"
        
        // Kubernetes Configuration
        K8S_NAMESPACE = 'concert-platform'
        K8S_CREDENTIALS_ID = 'kubernetes-credentials'
        
        // Git Configuration
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        BUILD_TAG = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
    }
    
    options {
        timestamps()
        timeout(time: 60, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out code...'
                checkout scm
                sh 'git rev-parse --short HEAD > .git/commit-id'
            }
        }
        
        stage('Build Backend Docker Image') {
            steps {
                echo '🔨 Building backend Docker image...'
                dir('main_backend') {
                    script {
                        docker.build("${BACKEND_IMAGE}:${BUILD_TAG}", "--build-arg SKIP_TESTS=false .")
                        docker.build("${BACKEND_IMAGE}:latest", "--build-arg SKIP_TESTS=false .")
                    }
                }
            }
        }
        
        stage('Build Frontend Docker Image') {
            steps {
                echo '🔨 Building frontend Docker image...'
                dir('main_frontend/concert1') {
                    script {
                        docker.build("${FRONTEND_IMAGE}:${BUILD_TAG}", ".")
                        docker.build("${FRONTEND_IMAGE}:latest", ".")
                    }
                }
            }
        }
        
        stage('Run Backend Tests') {
            steps {
                echo '🧪 Running backend tests...'
                dir('main_backend') {
                    script {
                        // Run tests with coverage
                        sh '''
                            mvn clean test jacoco:report \
                                -DforkCount=1 \
                                -DreuseForks=false \
                                -Dtest="*Test,*IntegrationTest,*DockerTest"
                        '''
                    }
                }
            }
            post {
                always {
                    // Publish test results
                    junit 'main_backend/target/surefire-reports/*.xml'
                    
                    // Publish coverage report
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'main_backend/target/site/jacoco',
                        reportFiles: 'index.html',
                        reportName: 'Backend Coverage Report'
                    ])
                }
            }
        }
        
        stage('Run Frontend Tests') {
            steps {
                echo '🧪 Running frontend tests...'
                dir('main_frontend/concert1') {
                    script {
                        sh '''
                            npm ci
                            npm run test -- --coverage
                        '''
                    }
                }
            }
            post {
                always {
                    // Publish coverage report
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'main_frontend/concert1/coverage',
                        reportFiles: 'index.html',
                        reportName: 'Frontend Coverage Report'
                    ])
                }
            }
        }
        
        stage('Security Scan') {
            parallel {
                stage('Backend Security Scan') {
                    steps {
                        echo '🔒 Scanning backend for vulnerabilities...'
                        script {
                            // Using Trivy for vulnerability scanning
                            sh """
                                docker run --rm \
                                    -v /var/run/docker.sock:/var/run/docker.sock \
                                    aquasec/trivy:latest image \
                                    --exit-code 0 \
                                    --severity HIGH,CRITICAL \
                                    --no-progress \
                                    ${BACKEND_IMAGE}:${BUILD_TAG}
                            """
                        }
                    }
                }
                stage('Frontend Security Scan') {
                    steps {
                        echo '🔒 Scanning frontend for vulnerabilities...'
                        script {
                            sh """
                                docker run --rm \
                                    -v /var/run/docker.sock:/var/run/docker.sock \
                                    aquasec/trivy:latest image \
                                    --exit-code 0 \
                                    --severity HIGH,CRITICAL \
                                    --no-progress \
                                    ${FRONTEND_IMAGE}:${BUILD_TAG}
                            """
                        }
                    }
                }
            }
        }
        
        stage('Push Docker Images') {
            when {
                branch 'main'
            }
            steps {
                echo '📤 Pushing Docker images to registry...'
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS_ID) {
                        // Push backend images
                        docker.image("${BACKEND_IMAGE}:${BUILD_TAG}").push()
                        docker.image("${BACKEND_IMAGE}:latest").push()
                        
                        // Push frontend images
                        docker.image("${FRONTEND_IMAGE}:${BUILD_TAG}").push()
                        docker.image("${FRONTEND_IMAGE}:latest").push()
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                echo '🚀 Deploying to Kubernetes...'
                script {
                    withKubeConfig([credentialsId: K8S_CREDENTIALS_ID]) {
                        // Update image tags in deployments
                        sh """
                            # Create namespace if not exists
                            kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                            
                            # Apply configurations
                            kubectl apply -f k8s/configmap.yaml -n ${K8S_NAMESPACE}
                            kubectl apply -f k8s/mysql.yaml -n ${K8S_NAMESPACE}
                            
                            # Wait for MySQL to be ready
                            kubectl wait --for=condition=ready pod -l app=mysql -n ${K8S_NAMESPACE} --timeout=300s || true
                            
                            # Deploy backend with new image
                            kubectl set image deployment/backend backend=${BACKEND_IMAGE}:${BUILD_TAG} -n ${K8S_NAMESPACE} || \
                                kubectl apply -f k8s/backend.yaml -n ${K8S_NAMESPACE}
                            
                            # Deploy frontend with new image
                            kubectl set image deployment/frontend frontend=${FRONTEND_IMAGE}:${BUILD_TAG} -n ${K8S_NAMESPACE} || \
                                kubectl apply -f k8s/frontend.yaml -n ${K8S_NAMESPACE}
                            
                            # Apply ingress
                            kubectl apply -f k8s/ingress.yaml -n ${K8S_NAMESPACE}
                            
                            # Wait for deployments to be ready
                            kubectl rollout status deployment/backend -n ${K8S_NAMESPACE} --timeout=300s
                            kubectl rollout status deployment/frontend -n ${K8S_NAMESPACE} --timeout=300s
                        """
                    }
                }
            }
        }
        
        stage('Smoke Tests') {
            when {
                branch 'main'
            }
            steps {
                echo '🔍 Running smoke tests...'
                script {
                    withKubeConfig([credentialsId: K8S_CREDENTIALS_ID]) {
                        sh """
                            # Get backend service endpoint
                            BACKEND_IP=\$(kubectl get svc backend-service -n ${K8S_NAMESPACE} -o jsonpath='{.spec.clusterIP}')
                            
                            # Test backend health endpoint
                            kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n ${K8S_NAMESPACE} -- \
                                curl -f http://\${BACKEND_IP}:8080/actuator/health || exit 1
                            
                            # Get frontend service endpoint
                            FRONTEND_IP=\$(kubectl get svc frontend-service -n ${K8S_NAMESPACE} -o jsonpath='{.spec.clusterIP}')
                            
                            # Test frontend health endpoint
                            kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n ${K8S_NAMESPACE} -- \
                                curl -f http://\${FRONTEND_IP}/ || exit 1
                            
                            echo "✅ Smoke tests passed!"
                        """
                    }
                }
            }
        }
        
        stage('Cleanup Old Images') {
            when {
                branch 'main'
            }
            steps {
                echo '🧹 Cleaning up old Docker images...'
                script {
                    sh """
                        # Remove dangling images
                        docker image prune -f
                        
                        # Keep only last 5 tagged images for each service
                        docker images ${BACKEND_IMAGE} --format '{{.Tag}}' | grep -v latest | tail -n +6 | xargs -I {} docker rmi ${BACKEND_IMAGE}:{} || true
                        docker images ${FRONTEND_IMAGE} --format '{{.Tag}}' | grep -v latest | tail -n +6 | xargs -I {} docker rmi ${FRONTEND_IMAGE}:{} || true
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            script {
                if (env.BRANCH_NAME == 'main') {
                    // Send success notification
                    slackSend(
                        color: 'good',
                        message: """
                            ✅ Deployment Successful!
                            Project: ${env.JOB_NAME}
                            Build: #${env.BUILD_NUMBER}
                            Backend Image: ${BACKEND_IMAGE}:${BUILD_TAG}
                            Frontend Image: ${FRONTEND_IMAGE}:${BUILD_TAG}
                            Duration: ${currentBuild.durationString}
                        """,
                        channel: '#deployments'
                    )
                }
            }
        }
        
        failure {
            echo '❌ Pipeline failed!'
            script {
                // Send failure notification
                slackSend(
                    color: 'danger',
                    message: """
                        ❌ Deployment Failed!
                        Project: ${env.JOB_NAME}
                        Build: #${env.BUILD_NUMBER}
                        Stage: ${env.STAGE_NAME}
                        Check: ${env.BUILD_URL}
                    """,
                    channel: '#deployments'
                )
                
                // Attempt rollback on deployment failure
                if (env.STAGE_NAME == 'Deploy to Kubernetes' || env.STAGE_NAME == 'Smoke Tests') {
                    withKubeConfig([credentialsId: K8S_CREDENTIALS_ID]) {
                        sh """
                            echo "⚠️ Attempting rollback..."
                            kubectl rollout undo deployment/backend -n ${K8S_NAMESPACE} || true
                            kubectl rollout undo deployment/frontend -n ${K8S_NAMESPACE} || true
                        """
                    }
                }
            }
        }
        
        always {
            echo '🧹 Cleaning workspace...'
            cleanWs()
        }
    }
}

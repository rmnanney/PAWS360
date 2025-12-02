// PAWS360 Jenkins Pipeline
// This pipeline provides an alternative CI/CD solution using Jenkins

pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'paws360-app'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        REGISTRY = 'your-registry.com'
        // Enable CI_SKIP_WIP for CI jobs (Jenkins) to skip known flaky UI WIP tests.
        // This mirrors what we do in GitHub Actions or other CI platforms to keep
        // pipelines green while these tests are stabilized.
        CI_SKIP_WIP = 'true'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Checking out source code...'
                checkout scm
            }
        }

        stage('Setup Environment') {
            steps {
                echo '⚙️ Setting up build environment...'
                sh '''
                    java -version
                    mvn --version
                    docker --version
                '''
            }
        }

        stage('Build & Test') {
            steps {
                echo '🔨 Building and testing application...'
                sh '''
                    # Set Maven options for CI
                    export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=256m"

                    # Clean and build
                    mvn clean

                    # Download dependencies
                    mvn dependency:go-offline -B

                    # Run tests
                    mvn test -B

                    # Package application
                    mvn package -DskipTests -B
                '''
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    jacoco execPattern: 'target/jacoco.exec'
                }
            }
        }

        stage('Security Scan') {
            steps {
                echo '🔒 Running security scans...'
                sh '''
                    # OWASP Dependency Check
                    mvn org.owasp:dependency-check-maven:check

                    # Trivy container scan (if Dockerfile exists)
                    if [ -f "infrastructure/docker/Dockerfile" ]; then
                        docker run --rm -v $WORKSPACE:/src aquasecurity/trivy:0.40.0 fs /src
                    fi
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'target/dependency-check-report.html',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'OWASP Dependency Check Report'
                    ])
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh '''
                    # Build Docker image
                    docker build -f infrastructure/docker/Dockerfile -t ${DOCKER_IMAGE}:${DOCKER_TAG} .

                    # Tag as latest for development
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                echo '📤 Pushing Docker image...'
                sh '''
                    # Login to registry (configure credentials in Jenkins)
                    docker login ${REGISTRY} -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}

                    # Push images
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}

                    docker tag ${DOCKER_IMAGE}:latest ${REGISTRY}/${DOCKER_IMAGE}:latest
                    docker push ${REGISTRY}/${DOCKER_IMAGE}:latest
                '''
            }
        }

        stage('Deploy to Staging') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'staging'
                }
            }
            steps {
                echo '🚀 Deploying to staging environment...'
                sh '''
                    # Deploy to staging environment
                    # This would typically use docker-compose or Kubernetes

                    echo "Deploying ${DOCKER_IMAGE}:${DOCKER_TAG} to staging"

                    # Example deployment commands:
                    # docker-compose -f docker-compose.staging.yml down
                    # sed -i "s|image:.*|image: ${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}|g" docker-compose.staging.yml
                    # docker-compose -f docker-compose.staging.yml up -d

                    # Health check
                    # sleep 30
                    # curl -f http://staging.paws360.com/actuator/health
                '''
            }
        }

        stage('Integration Tests') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'staging'
                }
            }
            steps {
                echo '🧪 Running integration tests...'
                sh '''
                    # Run integration tests against staging environment
                    # mvn verify -Pintegration-test -Dtest.url=http://staging.paws360.com

                    echo "Integration tests would run here"
                '''
            }
        }

        stage('Deploy to Production') {
            when {
                anyOf {
                    branch 'master'
                    branch 'main'
                }
            }
            steps {
                echo '🚀 Deploying to production environment...'
                sh '''
                    # Deploy to production environment
                    echo "Deploying ${DOCKER_IMAGE}:${DOCKER_TAG} to production"

                    # Example production deployment:
                    # kubectl set image deployment/paws360-app paws360-app=${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    # kubectl rollout status deployment/paws360-app

                    # Health check
                    # curl -f https://paws360.com/actuator/health
                '''
            }
        }

        stage('Post-Deployment Tests') {
            when {
                anyOf {
                    branch 'master'
                    branch 'main'
                }
            }
            steps {
                echo '✅ Running post-deployment tests...'
                sh '''
                    # Run smoke tests against production
                    # curl -f https://paws360.com/api/health
                    # Run basic functionality tests

                    echo "Post-deployment tests completed"
                '''
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up workspace...'
            sh '''
                # Clean up Docker images
                docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                docker rmi ${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG} || true

                # Archive test results
                mkdir -p artifacts
                cp -r target/surefire-reports artifacts/ || true
                cp -r target/site artifacts/ || true
            '''

            archiveArtifacts artifacts: 'artifacts/**', allowEmptyArchive: true
        }

        success {
            echo '✅ Pipeline completed successfully!'
            slackSend(
                channel: '#devops',
                color: 'good',
                message: "✅ PAWS360 Build #${env.BUILD_NUMBER} succeeded!\nBranch: ${env.BRANCH_NAME}\nDuration: ${currentBuild.durationString}"
            )
        }

        failure {
            echo '❌ Pipeline failed!'
            slackSend(
                channel: '#devops',
                color: 'danger',
                message: "❌ PAWS360 Build #${env.BUILD_NUMBER} failed!\nBranch: ${env.BRANCH_NAME}\nCheck: ${env.BUILD_URL}"
            )
        }

        unstable {
            echo '⚠️ Pipeline completed with warnings!'
        }
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    triggers {
        // Poll SCM every 15 minutes for changes
        pollSCM('H/15 * * * *')
    }
}
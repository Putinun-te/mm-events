pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
    durabilityHint('PERFORMANCE_OPTIMIZED')
    buildDiscarder(logRotator(numToKeepStr: '15'))
  }

  environment {
    JAVA_HOME = tool(name: 'JDK21', type: 'jdk')
    PATH = "${JAVA_HOME}/bin:${env.PATH}"
    REGISTRY = credentials('docker-registry-url') // e.g. https://registry.example.com
    REGISTRY_CREDENTIALS = 'docker-registry-creds' // Jenkins credential ID (username+password or token)
    BACKEND_IMAGE = 'concert-backend'
    BACKEND_IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}".replaceAll('[^A-Za-z0-9_.-]','-')
    NODE_VERSION = '20'
  }

  triggers {
    // For multibranch this is optional; remove if using Git hook plugin
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Backend Tests & Coverage') {
      steps {
        sh '''
          set -euo pipefail
          echo "== Start MySQL container (compose) =="
          docker compose up -d mysql
          echo "== Wait for MySQL =="
          for i in {1..60}; do \
            if docker exec concert-mysql mysqladmin ping -h 127.0.0.1 -uroot -ppassword --silent; then echo UP; break; fi; sleep 2; done
          echo "== Run backend test container =="
          docker compose run --rm backend-tests bash -lc "mvn -B -T 1C -Djacoco.haltOnFailure=false test jacoco:report"
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'main_backend/target/site/jacoco/**', allowEmptyArchive: true
          junit allowEmptyResults: true, testResults: 'main_backend/target/surefire-reports/*.xml'
        }
      }
    }

    stage('Frontend Install & E2E (Playwright)') {
      agent { docker { image "node:${NODE_VERSION}-alpine" args '-u root:root' } }
      steps {
        sh '''
          set -euo pipefail
          cd main_frontend/concert1
          npm ci
          npx playwright install --with-deps chromium
          # Start backend (if not already)
          if ! curl -sf http://host.docker.internal:8080/actuator/health >/dev/null 2>&1; then
            echo "Backend assumed running from earlier stage on host Docker daemon";
          fi
          npm run dev &
          NUXT_PID=$!
          for i in {1..60}; do if curl -sf http://localhost:3000/concert/ >/dev/null; then echo Frontend up; break; fi; sleep 2; done
          npm run test:e2e || EXIT_CODE=$?
          kill $NUXT_PID || true
          exit ${EXIT_CODE:-0}
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'main_frontend/concert1/playwright-report/**', allowEmptyArchive: true
        }
      }
    }

    stage('Build Backend Jar') {
      steps {
        sh '''
          set -euo pipefail
          cd main_backend
          mvn -B -DskipTests package
        '''
        archiveArtifacts artifacts: 'main_backend/target/*.jar', fingerprint: true
      }
    }

    stage('Build & Push Backend Docker Image') {
      when { expression { return env.BRANCH_NAME == 'main' } }
      steps {
        withCredentials([usernamePassword(credentialsId: env.REGISTRY_CREDENTIALS, usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''
            set -euo pipefail
            echo "== Docker login =="
            echo "$REG_PASS" | docker login "$REGISTRY" -u "$REG_USER" --password-stdin
            docker build -t $REGISTRY/$BACKEND_IMAGE:$BACKEND_IMAGE_TAG -f main_backend/Dockerfile main_backend
            docker push $REGISTRY/$BACKEND_IMAGE:$BACKEND_IMAGE_TAG
          '''
        }
      }
    }
  }

  post {
    success { echo 'Pipeline completed successfully.' }
    failure { echo 'Pipeline failed.' }
    always  { sh 'docker compose down || true' }
  }
}

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
    PLAYWRIGHT_BASE_URL = 'http://localhost:3000/concert/'
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
          if ! docker exec concert-mysql mysqladmin ping -h 127.0.0.1 -uroot -ppassword --silent; then
            echo "MySQL did not become ready in time" >&2
            exit 1
          fi
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

          echo "== Check backend API readiness =="
          # Try auth test endpoint (public) up to 60 * 2s = 120s
          for i in {1..60}; do if curl -sf http://host.docker.internal:8080/api/auth/test >/dev/null; then echo Backend API up; break; fi; sleep 2; done
          if ! curl -sf http://host.docker.internal:8080/api/auth/test >/dev/null; then
            echo "Backend API not responding after timeout" >&2
            exit 1
          fi

          echo "== Start Nuxt dev =="
          npm run dev &
          NUXT_PID=$!

          echo "== Wait for frontend ${PLAYWRIGHT_BASE_URL} =="
          for i in {1..60}; do if curl -sf "${PLAYWRIGHT_BASE_URL}" >/dev/null; then echo Frontend up; break; fi; sleep 2; done
          if ! curl -sf "${PLAYWRIGHT_BASE_URL}" >/dev/null; then
            echo "Frontend did not become ready" >&2
            kill $NUXT_PID || true
            exit 1
          fi

          echo "== Run Playwright tests =="
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
            # Also tag latest for main
            docker tag $REGISTRY/$BACKEND_IMAGE:$BACKEND_IMAGE_TAG $REGISTRY/$BACKEND_IMAGE:latest
            docker push $REGISTRY/$BACKEND_IMAGE:$BACKEND_IMAGE_TAG
            docker push $REGISTRY/$BACKEND_IMAGE:latest
          '''
        }
      }
    }
  }

  post {
    success { echo 'Pipeline completed successfully.' }
    failure { echo 'Pipeline failed.' }
    always  {
      sh '''
        set +e
        mkdir -p docker-logs
        docker compose ps > docker-logs/ps.txt 2>&1 || true
        docker compose logs --no-color > docker-logs/stack.log 2>&1 || true
        docker compose down || true
      '''
      archiveArtifacts artifacts: 'docker-logs/**', allowEmptyArchive: true
    }
  }
}

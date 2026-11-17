pipeline {
    agent any

    environment {
        DOCKER_REPO  = 'ambuj2k19/9nov'
        IMAGE_TAG    = "${JOB_NAME.replaceAll('[^a-zA-Z0-9_.-]', '-')}-${BUILD_NUMBER}"
        K8S_NS       = 'mytg'
        DOCKER_CREDS = credentials('dockerhub-creds')
    }

    parameters {
        string(name: 'PERSON', defaultValue: 'Mr Jenkins Kumar', description: 'Who triggered the build')
        choice(name: 'whereto', choices: ['TEST', 'STAGE', 'ACC'], description: 'Target environment')
    }

    triggers {
        pollSCM('* * * * *')
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Build Info') {
            steps {
                echo "Hello ${params.PERSON}, deploying to ${params.whereto}"
                sh '''
                    echo "Build Number --> $BUILD_ID"
                    echo "Project name --> $JOB_NAME"
                    echo "Image tag    --> $IMAGE_TAG"
                    echo "Workspace    --> $WORKSPACE"
                    whoami
                    pwd
                    hostname
                    ls -ltr
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build --no-cache -t $DOCKER_REPO:$IMAGE_TAG .'
            }
        }

        stage('Docker Push') {
            steps {
                sh '''
                    echo "$DOCKER_CREDS_PSW" | docker login -u "$DOCKER_CREDS_USR" --password-stdin
                    docker push $DOCKER_REPO:$IMAGE_TAG
                    docker logout
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    kubectl get ns $K8S_NS || kubectl create ns $K8S_NS
                    sed -i "s|JOB_NAME-BUILD_NUMBER|$IMAGE_TAG|g" tomcat-deploy.yaml
                    kubectl apply -f service.yaml
                    kubectl apply -f tomcat-deploy.yaml
                    kubectl rollout status deployment/myapp1 -n $K8S_NS --timeout=120s
                '''
            }
        }

        stage('Verify') {
            steps {
                sh '''
                    kubectl get all -n $K8S_NS
                    kubectl get svc -n $K8S_NS
                '''
            }
        }
    }

    post {
        success { echo "Build ${BUILD_NUMBER} deployed successfully" }
        failure { echo "Build ${BUILD_NUMBER} FAILED" }
        always {
            node('') {
                sh 'docker image prune -f || true'
            }
        }
    }
}

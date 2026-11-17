pipeline {
    agent { label 'master.tg.com' }

    environment {
        DOCKER_REPO  = 'ambuj2k19/9nov'
        JOB_TAG      = "${JOB_NAME.replaceAll('[^a-zA-Z0-9_.-]', '-')}"
        IMAGE_TAG    = "${JOB_TAG}-${BUILD_NUMBER}"
        K8S_NS       = 'mytg'
        DOCKER_USER  = 'ambuj2k19'
        DOCKER_TOKEN = 'dckr_pat_OVRwqkDTK9J68andjc6aMeSACdU'
    }

    parameters {
        string(name: 'PERSON', defaultValue: 'Mr Jenkins Kumar', description: 'Who triggered the build')
        choice(name: 'whereto', choices: ['TEST', 'STAGE', 'ACC'], description: 'Target environment')
    }

    triggers {
        pollSCM('H/5 * * * *')
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
                    docker ps
                    kubectl get nodes
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
                    echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin
                    docker push $DOCKER_REPO:$IMAGE_TAG
                    docker logout
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    kubectl get ns $K8S_NS || kubectl create ns $K8S_NS
                    kubectl create secret docker-registry passwd-for-docker-hub \
                      --docker-username=$DOCKER_USER --docker-password=$DOCKER_TOKEN \
                      -n $K8S_NS --dry-run=client -o yaml | kubectl apply -f -

                    sed -i "s|JOB_NAME|${JOB_TAG}|g" tomcat-deploy.yaml
                    sed -i "s|BUILD_NUMBER|${BUILD_NUMBER}|g" tomcat-deploy.yaml

                    grep image: tomcat-deploy.yaml
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

        stage('Cleanup') {
            steps {
                sh 'docker image prune -f || true'
            }
        }
    }

    post {
        success { echo "Build ${BUILD_NUMBER} deployed successfully" }
        failure { echo "Build ${BUILD_NUMBER} FAILED" }
    }
}

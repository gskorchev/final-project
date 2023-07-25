pipeline {
    agent any
    environment{
        image_name="726426509618.dkr.ecr.eu-central-1.amazonaws.com/flaskapp"
        region="eu-central-1"
    }
    stages {
        stage("Build") {
            steps {
                sh '''
                aws ecr get-login-password --region $region | docker login --username AWS --password-stdin 726426509618.dkr.ecr.eu-central-1.amazonaws.com
                docker build -t $image_name:latest .
                '''
            }
        }
        stage("Push") {
            steps {
                sh '''
                docker push $image_name:latest
                '''
            }
        }
        stage("Deploy") {
            steps {
                sh '''
                helm upgrade flask helm/ --install --wait --atomic
                '''
            }
        }
    }
}
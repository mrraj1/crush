pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = 'AWS_ACCESS_KEY_ID'
        AWS_SECRET_ACCESS_KEY = 'AWS_SECRET_ACCESS_KEY'
        REGION = 'us-east-1'
        CLUSTER_NAME = 'nodeapp'  
        SERVICE_NAME = 'nodeapp-svc'
        REPO_NAME = 'jay-crush' 
        IMAGE_URI = "860005315103.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}" 
        EXECUTION_ROLE_ARN = 'arn:aws:iam::860005315103:role/ecs-task'
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/mrraj1/crush.git'        
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t $REPO_NAME:$BUILD_NUMBER .'
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    sh 'aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $IMAGE_URI'
                    sh 'docker tag $REPO_NAME:$BUILD_NUMBER $IMAGE_URI:$BUILD_NUMBER'
                    sh 'docker push $IMAGE_URI:$BUILD_NUMBER'

                    // Set IMAGE_TAG to BUILD_NUMBER immediately after pushing
                    env.IMAGE_TAG = "$BUILD_NUMBER"
                }
            }
        }

        stage('Register Task Definition') {
            steps {
                script {
                    // Register a new task definition revision with the updated image
                    def taskDefArn = sh(
                        script: """
                            aws ecs register-task-definition \
                            --family $SERVICE_NAME \
                            --network-mode awsvpc \
                            --requires-compatibilities FARGATE \
                            --cpu 256 \
                            --memory 512 \
                            --execution-role-arn $EXECUTION_ROLE_ARN \
                            --container-definitions '[{"name": "crush-jay", "image": "$IMAGE_URI:$IMAGE_TAG", "memory": 512, "cpu": 256, "essential": true, "portMappings": [{"containerPort": 80, "hostPort": 80, "protocol": "tcp"}]}]' \
                            --region $REGION \
                            --query taskDefinition.taskDefinitionArn \
                            --output text
                        """,
                        returnStdout: true
                    ).trim()

                    // Store the new task definition ARN as an environment variable
                    env.NEW_TASK_DEF_ARN = taskDefArn
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                script {
                    echo "Updating ECS service..."
                    // Update the ECS service to use the latest task definition revision
                    sh """
                        aws ecs update-service --cluster $CLUSTER_NAME \
                          --service $SERVICE_NAME \
                          --task-definition $NEW_TASK_DEF_ARN \
                          --force-new-deployment \
                          --region $REGION
                    """
                    // Fetch and log service events after deployment
                    sh """
                        aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION \
                          --query 'services[0].events[].[createdAt, message]' --output table
                    """
                }
            }
        }
    }
}


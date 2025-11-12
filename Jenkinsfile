pipeline {
    agent  {
        label 'AGENT-1'
    }
    environment {
        appVersion = ''
        REGION = "us-east-1"
        ACC_ID = "968220652823"
        PROJECT = "roboshop"
        COMPONENT = "catalogue"
    }
    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    parameters {
        booleanParam(name: 'deploy', defaultValue: false, description: 'toggle value')
    }
    // Build
    stages {
        stage('Read package.json') {
            steps {
                script {
                    def packageJson = readJSON file: 'package.json'
                    appVersion = packageJson.version
                    echo "Package version: ${appVersion}"
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                script {
                   sh """
                        npm install
                   """
                }
            }
        }
        // stage('sonar scan'){
        //     environment{
        //         scannerHome = tool 'sonar-7.2'
        //     }
        //     steps{
        //         script{
        //             withSonarQubeEnv(installationName: 'sonar-7.2'){
        //                 sh "${scannerHome}/bin/sonar-scanner" 
        //             }
                       
        //         }
        //     }
        // }
        // stage('quality gate'){
        //     steps{
        //         timeout(time: 1, unit: 'HOURS'){
        //             waitForQualityGate abortPipeline: false
        //         }
        //     }
        // }
        // stage('check dependabot'){
        //     environment{
        //         GITHUB_TOKEN = credentials('github-token')
        //     }
        //     steps{
        //         script{
        //             def response = sh(
        //                 script: """
        //                         curl -s -L \
        //                         -H "Accept: application/vnd.github+json" \
        //                         -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        //                         https://api.github.com/repos/Sameer-Sarrainodu/catalogue/dependabot/alerts
        //                 """,
        //                 returnStdout: true
        //             ).trim()

        //             def json = readJSON text: response
        //             def criticalOrHigh = json.findAll { alert ->

        //                 def severity = alert?.security_advisory?.severity?.toLowerCase()
        //                 def state = alert?.state?.toLowerCase()
        //                 return (state == "open" && (severity == "critical" || severity == "high"))
        //             }
        //             if (criticalOrHigh.size() > 0) {
        //                 error "❌ Found ${criticalOrHigh.size()} HIGH/CRITICAL Dependabot alerts. Failing pipeline!"
        //             } else {
        //                 echo "✅ No HIGH/CRITICAL Dependabot alerts found."
        //             }
        //         }
        //     }
        // }
        stage('Docker Build') {
            steps {
                script {
                    withAWS(credentials: 'aws-creds', region: REGION) {
                        sh """
                            aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 968220652823.dkr.ecr.us-east-1.amazonaws.com
                            docker build -t roboshop/catalogue .
                            docker tag roboshop/catalogue:${appVersion} 968220652823.dkr.ecr.us-east-1.amazonaws.com/roboshop/catalogue:${appVersion}
                            docker push 968220652823.dkr.ecr.us-east-1.amazonaws.com/roboshop/catalogue:${appVersion}

                        """
                    }
                }
            }
        }
        stage('Check Scan Results') {
            steps {
                script {
                    withAWS(credentials: 'aws-creds', region: REGION) {
                        sh """
                            echo "🔐 Logging in to AWS ECR..."
                            aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACC_ID}.dkr.ecr.${REGION}.amazonaws.com

                            echo "🐳 Building Docker image (forcing legacy builder and single-arch)..."
                            export DOCKER_BUILDKIT=0
                            export DOCKER_DEFAULT_PLATFORM=linux/amd64
                            docker build -t ${PROJECT}/${COMPONENT}:${appVersion} .

                            echo "🏷️  Tagging for ECR..."
                            docker tag ${PROJECT}/${COMPONENT}:${appVersion} ${ACC_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}/${COMPONENT}:${appVersion}

                            echo "🚀 Pushing image to ECR..."
                            docker push ${ACC_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}/${COMPONENT}:${appVersion}
                        """
                    }
                }
            }
        }
        stage('Trigger deploy') {
            when{
                expression { params.deploy }
            }
            steps {
                script {
                    build job: 'catalogue-cd',
                    parameters: [
                        string(name: 'appVersion', value: "${appVersion}"),
                        string(name: 'deploy_to', value: 'dev')
                    ],
                    propagate: false,
                    wait: false
                }
            }
        }

    }

    post {
        always {
            echo 'I will always say Hello again!'
            deleteDir()
        }
        success {
            echo 'Hello Success'
        }
        failure {
            echo 'Hello Failure'
        }
    }
}

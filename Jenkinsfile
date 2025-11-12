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
                    withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                        sh """
                                echo "🔐 Logging in to ECR..."
                                aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACC_ID}.dkr.ecr.${REGION}.amazonaws.com

                                echo "🐳 Building single-arch Docker image (amd64)..."
                                docker build --platform linux/amd64 -t ${ACC_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}/${COMPONENT}:${appVersion} .

                                echo "🚀 Pushing image to ECR..."
                                docker push ${ACC_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}/${COMPONENT}:${appVersion}
                        """
                    }
                }
            }
        }
        stage('Check Scan Results') {
            steps {
                script {
                    withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    // Fetch scan findings
                        def findings = sh(
                            script: """
                                aws ecr describe-image-scan-findings \
                                --repository-name ${PROJECT}/${COMPONENT} \
                                --image-id imageTag=${appVersion} \
                                --region ${REGION} \
                                --output json
                            """,
                            returnStdout: true
                        ).trim()

                        // Parse JSON
                        def json = readJSON text: findings

                        def highCritical = json.imageScanFindings.findings.findAll {
                            it?.severity == "HIGH" || it?.severity == "CRITICAL"
                        }

                        if (highCritical.size() > 0) {
                            echo "❌ Found ${highCritical.size()} HIGH/CRITICAL vulnerabilities!"
                            currentBuild.result = 'FAILURE'
                            error("Build failed due to vulnerabilities")
                        } else {
                            echo "✅ No HIGH/CRITICAL vulnerabilities found."
                        }
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

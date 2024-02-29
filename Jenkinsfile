pipeline {
    agent any
    stages {
        stage('init') {
            steps{
                sh '''terraform init'''
            }
        }
        stage('validate'){
            steps{
                sh ''' terraform validate '''
            }
        }
        stage('plan'){
            steps{
                script{
                   def output = sh(script: 'terraform plan', returnStdout: true).trim()
def message = " Job Name: ${env.JOB_NAME}\nBuild Number: ${env.BUILD_NUMBER}\nBuild URL: ${env.BUILD_URL}/console"
                }
            } 
        }
        stage('apply'){
            input{
                message "Do you want to continue"
                ok "Yes we should"
            }
            steps{
             script{
                   if (env.BRANCH_NAME=='terraform'){
                  sh ''' terraform apply -auto-approve'''
        }
                  else{
            echo "we cannot run terraform apply"
        }
             }
            }
        }
         stage('destroy'){
            input{
                message "Do you want to Destroy the infra"
                ok "Yes we should"
            }
            steps{
             script{
                   if (env.BRANCH_NAME=='terraform'){
                  sh ''' terraform destroy -auto-approve'''
        }
                  else{
            echo "we cannot run terraform destroy"
        }
             }
            }
        }

    }
}


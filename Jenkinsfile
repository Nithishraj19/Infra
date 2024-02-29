pipeline {
    agent any
    stages {
        stage('CleanWorkspace') {
            steps{
                cleanWs()
            }
        }
        stage('Fetch EC2 Public IP') {
            steps {
                script {
                    // Execute the AWS CLI command to fetch the public IP address
                    def publicIpAddress = sh(script: 'aws ec2 describe-instances --filters "Name=tag:Name,Values=Public_server" --query "Reservations[].Instances[].PublicIpAddress" --output text', returnStdout: true).trim()
                    
                    // Make the 'publicIpAddress' variable available as an environment variable
                    env.PUBLIC_IP = publicIpAddress
                }
            }
        }
        stage('Clone Ansible Repository on Server') {
            steps {
                script {
                    // SSH into the server and clone the Ansible repository (only ansible branch)
                    sshagent(credentials: ['sshcreds']) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${env.PUBLIC_IP} 'GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone -b ansible --single-branch git@github.com:suriya8299/Infrastructure.git /home/ubuntu/Infrastructure'
                        """
                    }
                }
            }
        }
        stage('Install Ansible and Dependencies') {
            steps {
                script {
                    // SSH into the server and run the commands using the 'publicIpAddress' environment variable
                    sshagent(['sshcreds']) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${env.PUBLIC_IP} "sudo apt-add-repository -y ppa:ansible/ansible && \
                            sudo apt update && \
                            sudo apt install -y ansible && \
                            sudo apt-get install -y python3 && \
                            sudo apt-get install -y python3-pip && \
                            sudo pip3 install boto3 && \
                            cd /home/ubuntu/Infrastructure && \
                            ansible-playbook -i aws_ec2.yaml main.yaml"
                        """
                    }
                }
            }
        }
    }
}
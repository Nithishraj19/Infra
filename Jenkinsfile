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
        stage('Clone or Pull Ansible Repository on Server') {
            steps {
                script {
                    // SSH into the server and check if the directory already exists
                    def directoryExists = sh(script: "ssh ubuntu@${env.PUBLIC_IP} '[ -d /home/ubuntu/Infrastructure ] && echo true || echo false'", returnStdout: true).trim()

                    if (directoryExists == 'true') {
                        echo "Directory '/home/ubuntu/Infrastructure' already exists. Performing git pull..."
                        sshagent(credentials: ['your-ssh-credentials-id']) {
                            sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${env.PUBLIC_IP} 'cd /home/ubuntu/Infrastructure && git pull'
                            """
                        }
                    } else {
                        echo "Directory '/home/ubuntu/Infrastructure' does not exist. Performing git clone..."
                        sshagent(credentials: ['your-ssh-credentials-id']) {
                            sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${env.PUBLIC_IP} 'git clone -o StrictHostKeyChecking=no -b ansible --single-branch git@github.com:suriya8299/Infrastructure.git /home/ubuntu/Infrastructure'
                            """
                        }
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
pipeline {
    agent any
    stages {
        stage('CleanWorkspace') {
            steps{
                cleanWs()
            }
        }
        stage('Install Ansible and Dependencies') {
            steps {
                script {
                    // SSH into the server and run the commands
                    sshagent(['sshcreds']) {
                        sh 'ssh -o StrictHostKeyChecking=no ubuntu@52.66.208.244 "sudo apt-add-repository -y ppa:ansible/ansible && \
                            sudo apt update && \
                            sudo apt install -y ansible && \
                            sudo apt-get install -y python3 && \
                            sudo apt-get install -y python3-pip && \
                            sudo pip3 install boto3"'
                    }
                }
            }
        }
    }
}


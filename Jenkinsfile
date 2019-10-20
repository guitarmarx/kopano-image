pipeline {
    agent {label 'build'}
    environment{
        dockerRegistry='registry.meteorit-leipzig.de'
        image="kopano"
        version="${BRANCH_NAME == 'master' ? 'latest' : BRANCH_NAME}"
    }
    stages {
        stage('Build Image'){
            steps{
                script {
                    sh "docker build --no-cache  -t $dockerRegistry/$image:$version ."
                }
            }
        }
        stage('Push image') {
            steps {
                 withDockerRegistry([ credentialsId: 'docker-registry-credential', url: 'https://' + dockerRegistry ]) {
                    sh "docker push $dockerRegistry/$image:$version"
                 }
            }
        }
    }
}
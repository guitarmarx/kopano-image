properties = null


pipeline {
    agent any
    environment{
        dockerRegistry='registry.meteorit-leipzig.de'
    }

    stages {
        stage('Build Image'){
            steps{
                script {
                    properties = readProperties  file:'docker.info';
                }
                imageName = $dockerRegistry + "/" + properties.name + ":" + properties.version
                sh "docker build --no-cache --build-arg  KOPANO_SERIAL=ZN4EG01D4EN93N2R90JLCJZZ4  -t $imageName"
            }
        }

        stage('Push image') {
            steps {
                 withDockerRegistry([ credentialsId: "docker-registry-credential", url: "https://" + $dockerRegistry ]) {
                    sh 'docker push $imageName'
                }
            }
        }
    }
}

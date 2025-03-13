pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true -Dmaven.compiler.release=17 -Djdk.module.illegalAccess=permit"
              archive 'target/*.jar' //so that they can be downloaded later
            }
        }   
    }
}

pipeline {
    agent any

    tools {
        jdk 'JDK17' // Matches the name from Global Tool Configuration
        maven 'Maven3' // Your Maven installation name
    }

    stages {
        stage('Build') {
            steps {
                withEnv(["MAVEN_OPTS=--add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED"]) {
                    sh 'mvn clean package -DskipTests=true -Dmaven.compiler.release=17'
                }
            }
        }
    }
}

FROM openjdk:17-jdk-alpine // Java 17 is installed, replace the docker image with 17
EXPOSE 8080
ARG JAR_FILE=target/*.jar
ADD ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]

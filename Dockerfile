FROM adoptopenjdk/openjdk11:alpine-jre

WORKDIR /opt/app

# Copy only the JAR that Maven built
COPY target/*.jar app.jar

ENTRYPOINT ["java","-jar","app.jar"]


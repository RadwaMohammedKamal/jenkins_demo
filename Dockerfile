FROM adoptopenjdk/openjdk11:alpine-jre

WORKDIR /opt/app

# Copy any JAR in workspace (after Maven build) into container
COPY *.jar app.jar

ENTRYPOINT ["java","-jar","app.jar"]


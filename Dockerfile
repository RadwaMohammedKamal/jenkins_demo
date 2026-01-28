# Base image with Java 11
FROM adoptopenjdk/openjdk11:alpine-jre

# Set working directory
WORKDIR /opt/app

# Copy any JAR file from target/ to the container as app.jar
COPY target/*.jar app.jar

# Run the application
ENTRYPOINT ["java","-jar","app.jar"]


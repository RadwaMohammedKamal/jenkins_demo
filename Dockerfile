FROM adoptopenjdk/openjdk11:alpine-jre

WORKDIR /opt/app

# Copy a small test file instead of big JAR
COPY test.txt test.txt

CMD ["cat", "test.txt"]


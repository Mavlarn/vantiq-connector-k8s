# Alpine Linux with OpenJDK JRE
FROM openjdk:8-jre-alpine
# copy jar into image
COPY ./*.jar  connector.jar
# run application with this command line
RUN chmod +x /connector.jar
CMD ["/usr/bin/java", "-jar", "/connector.jar"]


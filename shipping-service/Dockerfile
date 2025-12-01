FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8600
ENTRYPOINT ["java","-jar","app.jar"]

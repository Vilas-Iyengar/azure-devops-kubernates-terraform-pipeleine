#FROM maven:3.8.2-jdk-8-slim AS build
##WORKDIR /home/app
#COPY . /home/app
#RUN mvn -f /home/app/pom.xml clean package

FROM openjdk:10
EXPOSE 8000
COPY  target/currency-exchange.jar app.jar
ENTRYPOINT ["java","-jar","app.jar" ]
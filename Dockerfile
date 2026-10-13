FROM eclipse-temurin:21-jdk
WORKDIR /app

COPY . .
RUN chmod +x gradlew
RUN ./gradlew clean build --no-daemon

CMD ["java", "-version"]
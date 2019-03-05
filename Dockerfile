FROM jenkins/jenkins:2.150.3 as jenkins
USER root
ENV CWP_VERSION 1.0-SNAPSHOT
ADD tmp/output/target/jenkins-x-serverless-${CWP_VERSION}.war /usr/share/jenkins/jenkins.war
RUN mkdir /app && unzip /usr/share/jenkins/jenkins.war -d /app/jenkins
COPY tmp/output/jenkinsfileRunner /app
RUN chmod +x /app/bin/jenkinsfile-runner && mkdir -p /usr/share/jenkins/ref/plugins && \
  rm -rf /app/jenkins/scripts /app/jenkins/jsbundles /app/jenkins/css \
  /app/jenkins/images /app/jenkins/help /app/jenkins/WEB-INF/detached-plugins \
  /app/jenkins/winstone.jar /app/jenkins/WEB-INF/jenkins-cli.jar \
  /app/jenkins/WEB-INF/lib/jna-4.5.2.jar
COPY tmp/output/plugins /usr/share/jenkins/ref/plugins

FROM openjdk:8-jdk
RUN mkdir -p /app /usr/share/jenkins/ref/plugins

 # we don't need all the repo
COPY --from=jenkins /app/jenkins /app/jenkins
COPY --from=jenkins /app/bin /app/bin
COPY --from=jenkins /app/repo /app/repo
COPY --from=jenkins /usr/share/jenkins/ref/plugins /usr/share/jenkins/ref/plugins

ENTRYPOINT ["/app/bin/jenkinsfile-runner", \
            "-w", "/app/jenkins",\
            "-p", "/usr/share/jenkins/ref/plugins",\
            "-f", "/workspace/Jenkinsfile"]

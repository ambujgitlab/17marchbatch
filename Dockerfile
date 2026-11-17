FROM rockylinux:9.3.20231119

LABEL maintainer="ekamjeetsingh@gmail.com"

RUN dnf install -y vim java-17-openjdk java-17-openjdk-devel \
    && dnf clean all

COPY Dockerfile /root/

ADD apache-tomcat-8.5.89.tar.gz /opt

WORKDIR /opt/apache-tomcat-8.5.89/bin/

EXPOSE 8080

CMD ["/opt/apache-tomcat-8.5.89/bin/catalina.sh", "run"]

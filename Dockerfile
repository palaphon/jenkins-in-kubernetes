FROM jenkins/jenkins:lts

# Running as root to have an easy support for Docker
USER root

# A default admin user
ENV ADMIN_USER=admin \
    ADMIN_PASSWORD=P@ssw0rd

#add mycluster.icp to hosts file
RUN echo '122.155.223.7 mycluster.icp' >> /etc/hosts

# Jenkins init scripts
COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/

# Install plugins at Docker image build time
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/install-plugins.sh $(cat /usr/share/jenkins/plugins.txt) && \
    mkdir -p /usr/share/jenkins/ref/ && \
    echo lts > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state && \
    echo lts > /usr/share/jenkins/ref/jenkins.install.InstallUtil.lastExecVersion

# Install Docker
RUN apt-get -qq update && \
    apt-get -qq -y install curl && \
    curl -sSL https://get.docker.com/ | sh

# Install kubectl and helm
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

#copy helm
COPY helm_cli /usr/local/bin/helm

#copy Bluemix CLI
COPY Bluemix_CLI /root/Bluemix_CLI

#install bx 
RUN /root/Bluemix_CLI/install_bluemix_cli

#install bx plugin icp
RUN cd /root/Bluemix_CLI/ && \
    bx plugin install /root/Bluemix_CLI/icp-linux-amd64

#bx login
RUN bx pr login -a https://122.155.223.7:8443 --skip-ssl-validation -u admin -p P@ssw0rd -c id-mycluster-account

#list cluster
RUN bx pr clusters

#list cluster config
RUN bx pr cluster-config mycluster

#helm init
RUN helm init --client-only

#helm init upgrade
RUN helm init --force-upgrade

#helm version
RUN helm version --tls


FROM registry.redhat.io/ubi8 

# Install the required software
RUN yum update -y && yum install nmap tar curl -y

#Copy tar file from local
COPY oc.tar /tmp/

#Try and get updated version to overwrite, pass in case we can't get
RUN curl -o /tmp/oc.tar https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/oc/latest/linux/oc.tar.gz; exit 0

#Untar oc file
RUN tar -xzvf /tmp/oc.tar -C /tmp/ && mv /tmp/oc /usr/local/bin


# COPY HTMl File
COPY ./index.html /var/www/html
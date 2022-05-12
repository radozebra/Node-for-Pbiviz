FROM node:16.14

MAINTAINER Radovan Obal <radovan.obal@appicanis.si>

RUN apt-get update \
	&& apt-get install -y openssl libnss3-tools \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/cache/apt/*

RUN npm i -g powerbi-visuals-tools

COPY ./conf/openssl.cnf /tmp/openssl.cnf

RUN touch $HOME/.rnd \
    && openssl req -x509 -nodes -new -sha256 -days 1024 -newkey rsa:2048 -keyout /tmp/local-root-ca.key -out /tmp/local-root-ca.pem -subj "/C=US/CN=Local Root CA/O=Local Root CA" \
    && openssl x509 -outform pem -in /tmp/local-root-ca.pem -out /tmp/local-root-ca.crt

RUN PBIVIZ=`which pbiviz` \
    && PBIVIZ=`dirname $PBIVIZ` \
    && PBIVIZ="$PBIVIZ/../lib/node_modules/powerbi-visuals-tools/certs" \
    && openssl req -new -nodes -newkey rsa:2048 -keyout $PBIVIZ/PowerBIVisualTest_private.key -out $PBIVIZ/PowerBIVisualTest.csr -subj "/C=US/O=PowerBI Visuals/CN=localhost" #\
    && openssl x509 -req -sha256 -days 1024 -in $PBIVIZ/PowerBIVisualTest.csr -CA /tmp/local-root-ca.pem -CAkey /tmp/local-root-ca.key -CAcreateserial -extfile /tmp/openssl.cnf -out $PBIVIZ/PowerBIVisualTest_public.crt

RUN mkdir -p $HOME/.pki/nssdb \
    && certutil -d $HOME/.pki/nssdb -N \
    && certutil -A -n "Local Root CA" -t "CT,C,C" -i /tmp/local-root-ca.pem -d sql:$HOME/.pki/nssdb

RUN cp /tmp/local-root-ca.pem /usr/local/share/ca-certificates/ \
    && update-ca-certificates

#!/bin/bash


for i in {1..20}
do
    certname="pred-cli-cert-$i"

    if [ ! -d $HOME/ssl ]
    then
        mkdir $HOME/ssl
    fi

    if [ ! -f $HOME/ssl/rootCA.key ]
    then
        openssl genrsa -out $HOME/ssl/rootCA.key 4096
    fi

    if [ ! -f $HOME/ssl/rootCA.pem ]
    then
        openssl req -x509 -new -nodes -key $HOME/ssl/rootCA.key -sha256 -days 1024 -out $HOME/ssl/rootCA.pem -subj "/C=GB/ST=London/L=London/O=D2S/OU=PREDA/CN=PREDA Client Sig Auth"
    fi

    if [ ! -f $HOME/ssl/rootCA.crt ]
    then
        openssl x509 -in $HOME/ssl/rootCA.pem -inform PEM -out $HOME/ssl/rootCA.crt
    fi


    if [ ! -d $HOME/ssl/client ]
    then
        mkdir $HOME/ssl/client
    fi
    if [ ! -f $HOME/ssl/client/$certname.key ]
    then 
        openssl genrsa -out $HOME/ssl/client/$certname.key 4096
        openssl req -new -key $HOME/ssl/client/$certname.key -out $HOME/ssl/client/$certname.csr -subj "/C=GB/ST=London/L=London/O=D2S/OU=PREDA/CN=$certname"
    fi
    if [ ! -f $HOME/ssl/client/clientconf.cnf ]
    then
    cat > $HOME/ssl/client/clientconf.cnf<< EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF
    fi
    if [ ! -f $HOME/ssl/client/$certname.cert ]
    then 
        openssl x509 -req -in $HOME/ssl/client/$certname.csr -CA $HOME/ssl/rootCA.pem -CAkey $HOME/ssl/rootCA.key -CAcreateserial -out $HOME/ssl/client/$certname.cert -days 356 -extensions v3_req -extfile $HOME/ssl/client/clientconf.cnf
    fi
    if [ ! -f $HOME/ssl/client/$certname.pem ]
    then
     cat $HOME/ssl/client/$certname.key $HOME/ssl/client/$certname.cert > $HOME/ssl/client/$certname.pem
    fi
    if [ ! -f $HOME/ssl/client/$certname.pfx ]
    then
        openssl pkcs12 -export -in $HOME/ssl/client/$certname.pem  -out $HOME/ssl/client/$certname.pfx -passout pass:
    fi
done 
for i in {1..20}
do
    certname="pred-cli-cert-$i"
    echo -n "Cert Name: ${certname} : "
    fingerprint=$(openssl x509 -in $HOME/ssl/client/$certname.cert -noout -fingerprint |  awk -F= '{print $2}' | sed  "s|:||g")
    echo $fingerprint
done
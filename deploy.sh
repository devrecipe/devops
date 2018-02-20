#!/bin/bash

APP=$2
ENV=$1
NAME=$2-$1
COMMIT=$3
WEBSITE=$4
REGISTRY=registry.gitlab.com/devrecipe
K8S_FILE=/meshinum/deployments/$NAME.yaml
NGINX_FILE=/etc/nginx/sites/$WEBSITE
K8S_TEMPLATE=/meshinum/kubernetes-template
NGINX_TEMPLATE=/meshinum/nginx-template

echo "verbose: $ENV $APP $COMMIT $WEBSITE"

if [ -f $K8S_FILE ]
then
  kubectl set image deployment/$NAME $NAME=$REGISTRY/$APP:$COMMIT
else
  sudo mkdir -p `dirname $K8S_FILE`
  sudo cp $K8S_TEMPLATE $K8S_FILE
  sudo sed -i "s~app-env~$ENV~g" $K8S_FILE
  sudo sed -i "s~app-name~$APP~g" $K8S_FILE
  kubectl create -f $K8S_FILE
fi

IP=$(kubectl get services/$NAME | awk '{if (NR!=1) {print $3}}')

sudo cp $NGINX_TEMPLATE $NGINX_FILE
sudo sed -i "s~example.com~$WEBSITE~g" $NGINX_FILE
sudo sed -i "s~127.0.0.1~$IP~g" $NGINX_FILE

sudo letsencrypt --standalone -n --agree-tos --register-unsafely-without-email --webroot /var/www/html -d $WEBSITE
sudo nginx -t && sudo service nginx reload

#!/bin/bash


healthcheck(){
    echo "[DEPLOY INFO] Starting Heathcheck"

    h=true
    
    #Start custom healthcheck
    output=$(kubectl get pods -l version="$NEW_VERSION" -n $NAMESPACE --no-headers)
    echo "Got $output"
    s=($(echo "$output" | awk '{s+=$4}END{print s}'))
    c=($(echo "$output" | wc -l))

    if [ "$s" -gt "2" ]; then
        h=false
    fi
    ##if [ "$c" -lt "1" ]; then
    ##    h=false
    ##fi
    #End custom healthcheck

    if [ ! $h == true ]; then
        echo "[DEPLOY HEALTH] New color is unhealthy"
        cancel
    else
        echo "[DEPLOY HEALTH] New color is healthy."
    fi
}

cancel(){
    echo "[DEPLOY FAILED] Removing new color"
    
    kubectl delete deployment $DEPLOYMENT_NAME-$NEW_VERSION --namespace=${NAMESPACE}

    exit 1
}


mainloop(){
   
    echo "[DEPLOY INFO] Selecting Kubernetes cluster"
    kubectl config use-context "${KUBE_CONTEXT}"

    echo "[DEPLOY INFO] Locating current version"
    CURRENT_VERSION=$(kubectl get service $SERVICE_NAME -o=jsonpath='{.spec.selector.version}' --namespace=${NAMESPACE}) 

    if [ "$CURRENT_VERSION" == "$NEW_VERSION" ]; then
       echo "[DEPLOY NOP] NEW_VERSION is same as CURRENT_VERSION. Both are at $CURRENT_VERSION"
       exit 0
    fi    
    
    echo "[DEPLOY NEW COLOR] Creating next version"
    kubectl get deployment $DEPLOYMENT_NAME-$CURRENT_VERSION -o=yaml --namespace=${NAMESPACE} | sed -e "s/$CURRENT_VERSION/$NEW_VERSION/g" | kubectl apply --namespace=${NAMESPACE} -f -

    echo "[DEPLOY INFO] Waiting for new color to come up"
    kubectl rollout status deployment/$DEPLOYMENT_NAME-$NEW_VERSION --namespace=${NAMESPACE}

    echo "[DEPLOY INFO] Waiting for $HEALTH_SECONDS seconds before healthcheck"
    sleep $HEALTH_SECONDS

    healthcheck

    echo "[DEPLOY SWITCH] Routing traffic to new color"
    kubectl get service $SERVICE_NAME -o=yaml --namespace=${NAMESPACE} | sed -e "s/$CURRENT_VERSION/$NEW_VERSION/g" | kubectl apply --namespace=${NAMESPACE} -f - 
     

    echo "[DEPLOY CLEANUP] Removing previous color"
    kubectl delete deployment $DEPLOYMENT_NAME-$CURRENT_VERSION --namespace=${NAMESPACE} 
   
}

if [ "$1" != "" ] && [ "$2" != "" ] && [ "$3" != "" ] && [ "$4" != "" ] && [ "$5" != "" ] && [ "$6" != "" ]; then
    SERVICE_NAME=$1
    DEPLOYMENT_NAME=$2
    NEW_VERSION=$3
    HEALTH_COMMAND=$4
    HEALTH_SECONDS=$5
    NAMESPACE=$6
else
    
    echo "USAGE\n k8s-blue-green-rollout.sh [SERVICE_NAME] [DEPLOYMENT_NAME] [NEW_VERSION] [HEALTH_COMMAND] [HEALTH_SECONDS] [NAMESPACE]"
    echo "\t [SERVICE_NAME] - Name of the current service"
    echo "\t [DEPLOYMENT_NAME] - The name of the current deployment"
    echo "\t [NEW_VERSION] - The next version of the Docker image"
    echo "\t [HEALTH_COMMAND] - command to use as a health check (unused)"
    echo "\t [HEALTH_SECONDS] - Time to wait before checking health"
    echo "\t [NAMESPACE] - Namespace of the application"
    exit 1;
fi

echo $BASH_VERSION

mainloop

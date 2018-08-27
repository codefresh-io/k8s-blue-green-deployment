# Kubernetes blue green deployments

This repository holds a bash script that allows you to perform blue/green deployments on a Kubernetes cluster.
See also the respective [blog post](https://codefresh.io/kubernetes-tutorial/fully-automated-blue-green-deployments-kubernetes-codefresh/)

## Description

The script expects you to have an existing deployment and service on your K8s cluster. It does the following:

1. Finds the current deployment (by looking at the selector of the service)
1. Copies the old deployment to a new one changing the Docker image to the new version
1. Applies the new deployment on the cluster. At this point both deployments co-exist
1. Waits for a configurable amount of seconds
1. Checks the health of the new pods. If there are restarts, it considers the new deployment unhealthy. In that case it removes it and the cluster is unaffected by the deployment
1. If the health is ok it switches the service to point to the new deployment
1. It removes the old deployment

Of course during the wait period when both deployments are active, you are free to run your own additional
checks or integration tests to see if the new deployment is ok.

## Prerequisites

As a convention the script expects

1. The name of your deployment to be $APP_NAME-$VERSION
1. Your deployment should have a label that shows it version
1. Your service should point to the deployment by using *both* a version and label

Notice that the new color deployment created by the script will follow the same conventions. This
way each subsequent pipeline you run will work in the same manner.

You can see examples of the tags with the sample application:

* [service](example/service.yml)
* [deployment](example/deployment.yml)


## How to use the script on its own

The script needs one environment variable called `KUBE_CONTEXT` that selects the K8s cluster that will be used (if you have more than one)

The rest of the parameters are provided as command line arguments

| Parameter | Argument Number | Description     |
| ----------| --------------- | --------------- |
| Service   |         1       | Name of the existing service |
| Deployment |        2       | Name of the existing deployment |
| New version |       3       | Tag of the new docker image    |
| Health command |   4        | Currently unused       |
| Health seconds | 5          | Time where both deployments will co-exist |
| Namespace |     6           | Kubernetes namespace that will be used |

Here is an example:

```
./k8s-blue-green.sh myService myApp 73df943 true 30 my-namespace
```



## How to do Blue/Green deployments in Codefresh

The script also comes with a Dockerfile that allows you to use it as a Docker image in any Docker based workflow such as Codefresh.

For the `KUBE_CONTEXT` environment variable just use the name of your cluster as found in the Codefresh Kubernetes dashboard. For the rest of the arguments you need to define them as parameters in your [codefresh.yml](example/codefresh.yml) file.

```
  blueGreenDeploy:
    title: "Deploying new version ${{CF_SHORT_REVISION}}"
    image: codefresh/k8s-blue-green:master
    environment:
      - SERVICE_NAME=my-demo-app
      - DEPLOYMENT_NAME=my-demo-app
      - NEW_VERSION=${{CF_SHORT_REVISION}}
      - HEALTH_SECONDS=60
      - NAMESPACE=colors
      - KUBE_CONTEXT=myDemoAKSCluster
```

The `CF_SHORT_REVISION` variable is offered by Codefresh and contains the git hash of the version that was just pushed. See all variables in the [official documentation](https://codefresh.io/docs/docs/codefresh-yaml/variables/)

## Dockerhub
The blue/green step is now deployed in dockerhub as well

https://hub.docker.com/r/codefresh/k8s-blue-green/


## Future work

Further improvements

* Make the script create an initial deployment/service if nothing is deployed in the kubernetes cluster
* Add more complex and configurable healthchecks



FROM codefresh/kube-helm:master

RUN mkdir /app

COPY k8s-blue-green.sh /app

RUN chmod +x /app/k8s-blue-green.sh
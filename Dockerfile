FROM codefresh/kube-helm:master

RUN mkdir /app

COPY k8s-canary-rollout.sh /app

RUN chmod +x /app/k8s-canary-rollout.sh
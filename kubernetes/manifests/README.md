requirements
------------
- Digital Ocean account
- Cert manager custom resource definition installed in the DO kuberntes cluster.
  https://github.com/cert-manager/cert-manager/releases
- Nginx-ingress controller
  https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes#step-2-setting-up-the-kubernetes-nginx-ingress-controller
- Google workplace for email relay
- A domain name other than example.com

Using these manifests
---------------------
TLDW: edit the manifests in this directory to reflect your setup and then apply them to your digital-ocean kubernetes cluster.

TODO
----
- Need to add persistent storage for the database

Abbreviations
-------------
- DO: Digital Ocean
- K8S: Kubernetes

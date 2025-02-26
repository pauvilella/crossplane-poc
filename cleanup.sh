#!/bin/sh

set -e

# Remove all Crossplane managed resources external to the cluster
echo "Suspending all flux kustomizations..."
flux suspend kustomization --all

echo "Deleting all Crossplane managed resources..."
kubectl delete managed --all

COUNTER=$(kubectl get managed --no-headers | wc -l)

while [ $COUNTER -ne 0 ]; do
	echo "$COUNTER resources still exist. Waiting for them to be deleted..."
	sleep 30
	COUNTER=$(kubectl get managed --no-headers | wc -l)
done

# Delete kind cluster

echo "Deleting kind management cluster..."
kind delete cluster

echo "All done! :)"

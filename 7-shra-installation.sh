echo "
██╗      ██████╗  ██████╗ ███████╗ ██████╗ █████╗ ██╗     ███████╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ 
██║     ██╔═══██╗██╔════╝ ██╔════╝██╔════╝██╔══██╗██║     ██╔════╝    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
██║     ██║   ██║██║  ███╗███████╗██║     ███████║██║     █████╗      ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝
██║     ██║   ██║██║   ██║╚════██║██║     ██╔══██║██║     ██╔══╝      ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗
███████╗╚██████╔╝╚██████╔╝███████║╚██████╗██║  ██║███████╗███████╗    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║
╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
"

#The script needs 2 parameters given to it
# - The parameters could be given to it in an interactive way; this happens if you run the script with no parameters and you'll have to provide it one by one.
# - As an alternative, you can run the parameters giving the first two parameters (HEC API Key, HEC API URL without '/services/collector').

export HEC_API_KEY
export HEC_API_URL

if [ $# -eq 2 ]
        then
                HEC_API_KEY=$1
                HEC_API_URL=$2
        else
                read -p "HEC API Key: " HEC_API_KEY
                read -p "HEC API URL without '/services/collector': " HEC_API_URL
fi

#Create the namespace where the LogScale Collector resources will be put
kubectl create namespace falcon-logscale-collector

#Create a secret for your HEC API key within Kubernetes
kubectl create secret generic logscale-collector-token \
  --from-literal=ingestToken=${HEC_API_KEY} \
  --namespace falcon-logscale-collector

#Add the LogScale Helm repository
helm repo add logscale-collector-helm https://registry.crowdstrike.com/log-collector-us1-prod


helm install -g logscale-collector-helm/logscale-collector \
  --create-namespace \
  --namespace falcon-logscale-collector \
  --set image="registry.crowdstrike.com/log-collector/us-1/release/logscale-collector:1.8.1" \
  --set resources.requests.cpu="100m" \
  --set humioAddress=${HEC_API_URL},humioIngestTokenSecretName=logscale-collector-token

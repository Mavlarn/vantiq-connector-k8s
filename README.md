# vantiq-connector-k8s
Deploy vantiq connector in k8s.


## Usage
1. build docker image with Dockerfile.
2. upload docker image to harbor or load in k8s worker nodes.
3. apply ConfigMap
4. apply Deployment

## build docker image
Copy the packaged jar in current directory, and build:
```
docker build -t vantiq/<connector-name>:1.0 .
```
From the *Dockerfile*, you can see we should package the connector as a uberjar file. If it is not, you should modify the *Dockerfile* to copy your directory and modify the *CMD*.


## upload docker image
To upload docker image to harbor, need to add a tag and push:
```
docker tag vantiq/<connector-name>:1.0 172.10.10.1:15000/vantiq/<connector-name>:1.0

# need to login to your docker repo.
docker login 172.10.10.1:15000

docker push 172.10.10.1:15000/vantiq/<connector-name>:1.0
```

Or just save your docker image as a *tar* file and load it in k8s nodes:
```
# export docker image to file
docker save vantiq/<connector-name>:1.0 -o connector-1.0.tar

# load into k8s nodes
docker load -i connector-1.0.tar
```

## register Source Type and Create source
In VANTIQ, we need to register the Source type and create a source of it using VANTIQ cli tool.

## deploy in k8s
At first, we need to create config map. Maybe you need to modify the content of the config map. The content is like this:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: iot-connector
  labels:
    app: iot-connector
    env: prod
  namespace: vantiq_ns
data:
  config.json: |-
    {
      "vantiqUrl": "https://test.thedomain.com:31554",
      "token": "<the_token>",
      "sourceName": "the_connector_source"
    }
```
The *iot-connector* is the name of the connector, and the name used in k8s as well. The *vantiq_ns* is the namespace that vantiq deployed.

Then create the config map in k8s with:
```
kubectl -n vantiq_ns apply connector-configmap.yaml
```

Then we can deploy the connector in k8s. Content deployment file is:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iot-connector-deployment
  labels:
    app: iot-connector
  namespace: vantiq_ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: iot-connector
  template:
    metadata:
      labels:
        app: iot-connector
    spec:
      hostAliases:
      - ip: "172.16.4.21"
        hostnames:
        - "test.stategrid.nx"
      containers:
      - name: iot-connector
        image: 172.10.10.1:15000/vantiq/iot-connector:1.0
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: config
          mountPath: /etc/config
      volumes:
      - name: config
        configMap:
          name: iot-connector
          items:
            - key: "config.json"
              path: "config.json"
```
Besides the name, there are something we should know and maybe need to modify:
 * hostAliases
Vantiq should be accessed with domain, and sometime, we have no DNS record for this domain, we can add host alias with this way.
 * volumeMounts and configMap
In connector, we get connector config file from `/etc/config/config.json`. Be aware that in the connector java file, we should also use this path to get config file.

Then we can just deploy the connector by:
```
kubectl -n vantiq_ns apply connector-deployment.yaml
```

You can check the logs to see its running status:
```
kubectl -n vantiq_ns logs iot-connector-xxxxx
```




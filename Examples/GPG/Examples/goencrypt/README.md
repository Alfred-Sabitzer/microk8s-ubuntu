# GOENCRYPT Exaample

This example is based on https://gist.github.com/r10r/1254039c940c426656e5d217216e0eec

# Build and deploy GO module

Here you will find the go sources and the routinges to build and deploy.

````bash
./go.sh
````

This command will build a local go (for testing purposes).

````bash
./do.sh
````

This command will build a docker-imaage and will deploy it to the corresponding docker repository.

````bash
./kubectl apply -f goencrypt.yaml
````

This commando will deploy all the necessary kubernetes elements.

````bash
./goencrypt-test.sh
````

This commando will execute some test-statements.
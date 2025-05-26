# REST API Serve MUX

This example is based on https://golang.cafe/blog/golang-rest-api-example.html 

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
./kubectl apply -f servemux.yaml
````

This commando will deploy all the necessary kubernetes elements.

````bash
./servemux-test.sh
````

This commando will execute some test-statements.
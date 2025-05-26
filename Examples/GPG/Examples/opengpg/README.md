# OPENGPG Exaample

This example is based on https://gist.github.com/ayubmalik/a83ee23c7c700cdce2f8c5bf5f2e9f20
See as well https://pkg.go.dev/golang.org/x/crypto/openpgp

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
./kubectl apply -f opengpg.yaml
````

This commando will deploy all the necessary kubernetes elements.


````bash
./opengpg-test.sh
````

This commando will execute some test-statements.
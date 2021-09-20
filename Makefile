all: container
container:
	packer build container.json
clean:
	docker rmi autechgemz/smokeping
push:
	docker push autechgemz/smokeping

all: image
image:
	packer build container.json
clean:
	docker rmi autechgemz/smokeping
	docker rmi autechgemz/smokeping

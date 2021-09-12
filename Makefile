all: image container
image:
	packer build baseimage.json
container:
	packer build container.json
clean:
	docker rmi autechgemz/smokeping-baseimage
	docker rmi autechgemz/smokeping

all: image container
image:
	packer build baseimage.json
container:
	packer build container.json
clean:
	docker rmi autechgemz/smokeping-baseimage
cleanall:
	docker rmi autechgemz/smokeping
push:
	docker push autechgemz/smokeping

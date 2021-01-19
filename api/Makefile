IMAGE = stv0g/connectiq-ura

all: push

image:
	docker build . -t $(IMAGE)

push: image
	docker push $(IMAGE)

build:
	docker build --tag mastery .

run:
	docker run --interactive --tty --rm --volume $(pwd):/app mastery

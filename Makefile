dev:
	jinja-static -s base -d public/ -w -f

prod:
	rm -rf public/
	jinja-static -s base -d public/ -p -f

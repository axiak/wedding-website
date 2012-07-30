dev:
	workon wws
	jinja-static -s base -d public/ -w -f

prod:
	workon wws
	rm -rf public/
	jinja-static -s base -d public/ -p -f


dev:
	rm -rf public/
	jinja-static -s base -d public/ -w -f -c static_config.yml

prod:
	rm -rf public/
	jinja-static -s base -d public/ -p -f -c static_config.yml

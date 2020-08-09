all: serve

install:
	bundle config set --local path 'vendor/bundle'
	bundle install

upgrade:
	bundle update

s serve:
	bundle exec jekyll serve --source docs --destination build/ --livereload --trace

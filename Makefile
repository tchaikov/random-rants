all: serve

install:
	bundle config set --local path 'vendor/bundle'
	bundle install

upgrade:
	bundle update

s serve:
	bundle exec jekyll serve   \
      --livereload           \
      --trace                \
      --open-url             \
      --incremental          \
      --watch								 \
      --drafts

r remote:
	bundle exec jekyll serve   \
      --livereload           \
      --trace                \
      --incremental          \
      --watch                \
      --drafts               \
      --host 0.0.0.0

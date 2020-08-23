# coding: utf-8
task :default => 'site:preview'

require 'rake'

def docs_folder
  'docs'
end

def slugify (title)
  # strip characters and whitespace to create valid filenames, also lowercase
  return title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
end

namespace :post do
  desc 'Create a new post'
  task :create, [:title, :categories, :draft] do |t, args|
    require 'yaml'
    require 'date'

    args.with_defaults(:title => nil,
                       :categories => 'misc',
                       :draft => false)
    if args.title == nil then
      puts 'Error! title is empty'
      exit 1
    end

    slug = slugify(args.title)
    date = Time.new.strftime('%Y-%m-%d %H:%M:%S %z')

    front_matter = { 'layout' => 'post',
                     'title' => args.title,
                     'date' => date,
                     'categories' => args.categories}
    if args.draft then
      front_matter['published'] = false
    end
    content = front_matter.to_yaml + "---\n"

    filename = File.join(docs_folder, '_posts', "#{Date.today}-#{slug}.md")
    if File.exist?(filename)
      puts "Error: #{filename} already exists"
      exit 1
    end

    if IO.write(filename, content)
      puts "Post #{filename} created"
    else
      puts "Error: #{filename} could not be written"
    end
  end
end

namespace :site do
  desc 'Peview the blog'
  task :preview do
    require 'launchy'
    require 'jekyll'

    browser_launched = false
    Jekyll::Hooks.register :site, :post_write do |_site|
      next if browser_launched
      browser_launched = true
      Jekyll.logger.info 'Opening in browser...'
      Launchy.open('http://localhost:4000')
    end

    # Generate the site in server mode.
    puts 'Running Jekyll...'
    options = {
      'source'      => File.expand_path(docs_folder),
      'destination' => File.expand_path("_site"),
      'livereload'  => true,
      'trace'       => true,
      'incremental' => true,
      'profile'     => true,
      'watch'       => true,
      'serving'     => true,
    }
    Jekyll::Commands::Build.process(options)
    Jekyll::Commands::Serve.process(options)
  end

  desc 'Push the changes to remote repo'
  task :push do
    current_branch = `git branch`.to_s.strip.match(%r!^\* (.+)$!)[1]
    sh "git push origin #{current_branch}"
  end
end

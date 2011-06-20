begin
  require 'rspec/core/rake_task'

  desc "Run specs"
  RSpec::Core::RakeTask.new do |t|
    t.rspec_opts = %w(-fs --color)
    t.ruby_opts  = %w(-w)
  end
rescue LoadError
  task :spec do
    abort "Run `rake spec:deps` to be able to run the specs"
  end

  namespace :spec do
    desc "Ensure spec dependencies are installed"
    task :deps do
      sh "gem list rspec | (grep 'rspec (2.0' 1> /dev/null) || gem install rspec --no-ri --no-rdoc"
    end
  end
end

desc "Build the gem"
task :build do
  gem_name = 'slight_assets'
  opers = Dir.glob('*.gem')
  opers = ["rm #{ opers.join(' ') }"] unless opers.empty?
  opers << ["gem build #{gem_name}.gemspec"]
  sh opers.join(" && ")
end

desc "Build and install the gem, removing old installation"
task :install => :build do
  gem_file = Dir.glob('*.gem').first
  gem_name = 'slight_assets'
  if gem_file.nil?
    puts "could not install the gem"
  else
    sh "gem uninstall --ignore-dependencies #{gem_name}; gem install #{ gem_file }"
  end
end

task :default => :spec

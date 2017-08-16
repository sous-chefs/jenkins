require 'chef/cookbook/metadata'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'foodcritic'
require 'kitchen'

namespace :style do
  desc 'Run Ruby style checks'
  RuboCop::RakeTask.new(:ruby)

  desc 'Run Chef style checks'
  FoodCritic::Rake::LintTask.new(:chef) do |t|
    t.options = {
      fail_tags: ['any'],
      tags: ['~FC024']
    }
  end
end

desc 'Run all style checks'
task style: ['style:ruby', 'style:chef']

desc 'Run ChefSpec'
RSpec::Core::RakeTask.new(:unit) do |tests|
  tests.pattern = './**/unit/**/*_spec.rb'
  tests.rspec_opts = '--format RspecJunitFormatter --out test-results.xml'
end

namespace :jenkins do
  desc 'Setup .chef directory'
  task :chef_dir do
    chefdir = '.chef/'
    mkdir(chefdir) unless Dir.exist?(chefdir)
    cp(ENV['JENKINSPEM'], chefdir)
    cp(ENV['FGSSECDEV'], chefdir)
    cp(ENV['KNIFECONFIG'], chefdir)
  end

  desc 'Cleanup .chef directory'
  task :cleanup_chef_dir do
    remove_dir('.chef')
  end

  desc 'Set version based on tag'
  task :set_cookbook_version do
    version = get_tag_name_from_branch_path(ENV['GIT_BRANCH'])

    File.open('VERSION', 'w') { |file| file.write(version) }
  end
end

def get_tag_name_from_branch_path(branch_path)
  tag_name_index = 2
  # rubocop:disable Style/RedundantReturn
  return branch_path.split('/')[tag_name_index]
end

task default: %w(style unit)

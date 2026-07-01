# frozen_string_literal: true

name 'jenkins'

run_list 'test::default'

cookbook 'jenkins', path: '.'
cookbook 'dpkg_autostart', git: 'https://github.com/sous-chefs/dpkg_autostart.git', branch: 'main'
cookbook 'java', git: 'https://github.com/sous-chefs/java.git', branch: 'main'
cookbook 'yum-epel', git: 'https://github.com/sous-chefs/yum-epel.git', branch: 'main'
cookbook 'test', path: './test/cookbooks/test'

Dir.children('./test/cookbooks/test/recipes').grep(/\.rb\z/).sort.each do |recipe|
  recipe_name = File.basename(recipe, '.rb')

  named_run_list recipe_name.to_sym, 'test::' + recipe_name
end

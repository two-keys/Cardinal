# frozen_string_literal: true

begin
  require 'rubocop/rake_task'
rescue LoadError => e
  raise e unless ENV.fetch('RAILS_ENV', nil) == 'production'
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['-A', '--display-cop-names'].concat ARGV.drop(1)
end

# frozen_string_literal: true

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop) do |t|
    t.options = ['-A', '--display-cop-names'].concat ARGV.drop(1)
  end
rescue LoadError
end



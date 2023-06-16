# frozen_string_literal: true
# rubocop:disable all

namespace :rubocop do
  begin
    require 'rubocop/rake_task'

    RuboCop::RakeTask.new(:lint) do |t|
      t.options = ['-A', '--display-cop-names'].concat ARGV.drop(1)
    end
  rescue LoadError
  end
end

# rubocop:enable all

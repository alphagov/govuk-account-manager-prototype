# frozen_string_literal: true

desc "Lint files"
task "lint" => :environment do
  sh "rubocop --format clang"
  sh "yarn run lint"
end

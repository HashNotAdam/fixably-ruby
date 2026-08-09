# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in fixably.gemspec
gemspec

# Mutation testing requires a licence, and each developer needs their own
# token. Rather than committing a token here, supply your own via either
#   bundle config set --global gem.mutant.dev com:YOUR_TOKEN
# or the equivalent environment variable
#   BUNDLE_GEM__MUTANT__DEV="com:YOUR_TOKEN"
# Without a token the licence gem is skipped so that `bundle install` still
# works; `bundle exec mutant` is then unavailable.
if Bundler.settings["gem.mutant.dev"]
  group :development do
    source "https://gem.mutant.dev" do
      gem "mutant-license"
    end
  end
end

source "https://rubygems.org"

# Specify your gem's dependencies in servizio.gemspec
gemspec

if !ENV["CI"]
  group :development do
    gem "pry",                "~> 0.9.12.6"
    gem "pry-byebug",         "<= 1.3.2"
    gem "pry-rescue",         "~> 1.4.1"
    gem "pry-stack_explorer", "~> 0.4.9.1"
    gem "pry-syntax-hacks",   "~> 0.0.6"
  end
end

group :test do
  gem "codeclimate-test-reporter", require: nil
end

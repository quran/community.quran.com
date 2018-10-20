require 'benchmark'
def require(file)
  puts Benchmark.measure("loading #{file}") {
    super
  }.format("%t require #{file}")
end

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

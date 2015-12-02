Gem::Specification.new do |s|
  s.name = 'tiered_caching'
  s.version = '0.1.5'
  s.license = 'Apache License 2.0'
  s.summary = 'Tiered caching for Ruby'
  s.description = %q{Tiered caching provides a simple, fast and easy to use
caching layer for Ruby that supports fast-slow cachings layers, basic replication,
serializing and namespacing of Ruby objects}
  s.authors = ['Thomas RM Rogers']
  s.email = 'thomasrogers03@gmail.com'
  s.files = Dir['{lib}/**/*.rb', 'bin/*', 'LICENSE.txt', '*.md']
  s.require_path = 'lib'
  s.homepage = 'https://www.github.com/thomasrogers03/tiered_caching'
  s.add_runtime_dependency 'thomas_utils', '~> 0.1'
  s.add_runtime_dependency 'concurrent-ruby', '~> 0.8'
end

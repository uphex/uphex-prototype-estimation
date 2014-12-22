$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

Gem::Specification.new do |spec|
	spec.name = 'uphex-estimation'
	spec.summary = 'UpHex time series estimation'
	spec.date = '2014-05-12'
	spec.version = '0.0.1'
	spec.authors = ['UpHex']
	spec.files = `git ls-files`.split("\n")
	spec.test_files = spec.files.grep('spec')
	spec.require_paths = ['lib']
	spec.add_development_dependency 'bundler', '~> 1.5'
	spec.add_development_dependency 'rake', '~> 0'
	spec.add_development_dependency 'rspec', '~> 0'
end

Pod::Spec.new do |s|
  s.name = 'Ladybug'
  s.version = '0.0.3-2'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.summary = 'Yet another Swift HTTP client'
  s.homepage = 'https://github.com/adamhartford/Ladybug'
  s.social_media_url = 'http://twitter.com/adamhartford'
  s.authors = { 'Adam Hartford' => 'adam@adamhartford.com' }
  s.source = { :git => 'https://github.com/adamhartford/Ladybug.git', :tag => "v#{s.version}", :branch => "swift2" }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'Ladybug/*.swift'

  s.requires_arc = true
end

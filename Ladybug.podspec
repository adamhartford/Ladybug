Pod::Spec.new do |s|
  s.name = 'Ladybug'
  s.version = '0.1.0'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.summary = 'Swift HTTP client built on WKWebView and jQuery''s $.ajax'
  s.homepage = 'https://github.com/adamhartford/Ladybug'
  s.social_media_url = 'http://twitter.com/adamhartford'
  s.authors = { 'Adam Hartford' => 'adam@adamhartford.com' }
  s.source = { :git => 'https://github.com/adamhartford/Ladybug.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'Ladybug/*.swift'
  s.resources = 'Ladybug/Web/*.js'

  s.requires_arc = true
end

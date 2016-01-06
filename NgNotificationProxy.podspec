Pod::Spec.new do |spec|
  spec.name         = 'NgNotificationProxy'
  spec.version      = '1.2'
  spec.summary      = 'Simple proxy implementation for observing notification posted with `NSNotificationCenter`.'
  spec.homepage     = 'https://github.com/meiwin/NgNotificationProxy'
  spec.author       = { 'Meiwin Fu' => 'meiwin@blockthirty.com' }
  spec.source       = { :git => 'https://github.com/meiwin/ngnotificationproxy.git', :tag => "v#{spec.version}" }
  spec.description  = 'NgNotificationProxy is built to make delivering notifications to particular threads a trivial task.'
  spec.source_files = 'NgNotificationProxy/*.{h,m}'
  spec.requires_arc = true
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.frameworks = 'Foundation'
  spec.ios.deployment_target = "5.0"
end
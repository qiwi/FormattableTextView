Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.name = 'FormattableTextView'
  s.summary = 'Framework which allows you to format user input according to your mask'
  s.requires_arc = true
  s.version = '1.0'
  s.license = { :type => 'MIT' }
  s.author   = { 'QIWI Wallet' => 'm.motyzhenkov@qiwi.com' }
  s.homepage = 'https://github.com/qiwi'
  s.source = { :git => 'https://github.com/qiwi/FormattableTextView' }

  s.framework = "UIKit"
  s.source_files = 'FormattableTextView/*.swift'
end
Pod::Spec.new do |s|

  s.name              = 'BMSAnalytics'
  s.version           = '2.2.4'
  s.summary           = 'The analytics component of the Swift client SDK for IBM Bluemix Mobile Services'
  s.homepage          = 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics'
  s.documentation_url = 'https://ibm-bluemix-mobile-services.github.io/API-docs/client-SDK/BMSAnalytics/Swift/index.html'
  s.license           = 'Apache License, Version 2.0'
  s.authors           = { 'IBM Bluemix Services Mobile SDK' => 'mobilsdk@us.ibm.com' }

  s.source       = { :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics.git', :tag => s.version }
  s.source_files = 'Source/**/*.swift'
  s.ios.exclude_files = 'Source/**/*watchOS*.swift'
  s.watchos.exclude_files = 'Source/**/*iOS*.swift'

  s.default_subspec = 'AnalyticsDep'
  s.requires_arc = true

  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'

  ### Subspecs

  s.subspec 'AnalyticsDep' do |cs|
    cs.dependency 'BMSCore', '~> 2.1'
    cs.dependency 'Zip', :git => 'https://github.com/marmelroy/Zip.git', :submodules => true, :branch => 'swift3' 
  end
end

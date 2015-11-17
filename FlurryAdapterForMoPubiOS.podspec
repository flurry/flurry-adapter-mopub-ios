Pod::Spec.new do |s|
  s.name             = "FlurryAdapterForMoPubiOS"
  s.version          = "7.2.1"
  s.summary          = "Flurry iOS Adapter for MoPub"
  s.homepage         = ""
  s.license          = ""
  s.source           = { :git => "", :tag => s.version.to_s }
  s.platform     = :ios, '6.0'
  s.requires_arc = true
  s.source_files = 'FlurryAdapterForMoPubiOS'
  s.dependency 'mopub-ios-sdk', '~> 4.1.0'
end

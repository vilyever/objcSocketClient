#
# Be sure to run `pod lib lint ${POD_NAME}.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "objcSocketClient"
  s.version          = "1.1.1"
  s.summary          = "sth useful."
  s.description      = <<-DESC
                       wait for next time.
                       DESC
  s.homepage         = "https://github.com/vilyever"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "vilyever" => "vilyever@gmail.com" }
  s.source           = { :git => "https://github.com/vilyever/objcSocketClient.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/vilyever'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'objcSocketClient/**/*.{h,m}'
#s.resource_bundles = {
#   'objcSocketClient' => ['objcSocketClient/**/*.png']
# }

  s.public_header_files = 'objcSocketClient/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

  s.dependency 'objcString'
  s.dependency 'objcTimer'
  s.dependency 'objcWeakRef'
  s.dependency 'objcBlock'
  s.dependency 'objcArray'
  s.dependency 'CocoaAsyncSocket'
end

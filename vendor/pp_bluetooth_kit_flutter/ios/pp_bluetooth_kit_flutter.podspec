#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pp_bluetooth_kit_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pp_bluetooth_kit_flutter'
  s.version          = '0.0.3'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '10.0'

  s.vendored_frameworks = [
    'Frameworks/PPBaseKit.xcframework',
    'Frameworks/PPBluetoothKit.xcframework',
    ]

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '$(inherited) -ObjC -all_load'  # 强制加载所有符号（包括分类）
  }
  s.swift_version = '5.0'
  
  s.dependency 'SSZipArchive'
end

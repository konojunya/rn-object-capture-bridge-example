require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'ModelViewer'
  s.version        = package['version']
  s.summary        = 'Expo module for viewing USDZ 3D models using SceneKit'
  s.description    = 'A local Expo module that wraps SceneKit SCNView to display USDZ 3D model files'
  s.license        = 'MIT'
  s.author         = 'konojunya'
  s.homepage       = 'https://github.com/konojunya/rn-object-capture-bridge-example'
  s.platforms      = { :ios => '15.1' }
  s.swift_version  = '5.9'
  s.source         = { git: 'https://github.com/konojunya/rn-object-capture-bridge-example.git' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  s.source_files = '**/*.{h,m,swift}'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }
end

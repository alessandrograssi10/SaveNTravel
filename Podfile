platform :ios, '12.0'

install! 'cocoapods', :warn_for_unused_master_specs_repo => false

target 'SaveNTravel' do
  use_frameworks!

  # Pods for SaveNTravel
  pod 'Firebase/Core'
  pod 'Firebase/Firestore'
  pod 'Firebase/Auth'
  pod 'PhoneNumberKit', '~> 3.7'

  target 'SaveNTravelTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'SaveNTravelUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      if target.name == 'BoringSSL-GRPC'
        target.source_build_phase.files.each do |file|
          if file.settings && file.settings['COMPILER_FLAGS']
            flags = file.settings['COMPILER_FLAGS'].split
            flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
            file.settings['COMPILER_FLAGS'] = flags.join(' ')
          end
        end
      end
      if defined?(flutter_additional_ios_build_settings)
        flutter_additional_ios_build_settings(target)
      end
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end

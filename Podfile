#source 'http://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

#igonre pod dSYM file
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
        end
    end
end

target 'KPS' do
  use_frameworks!
  # ignore all warnings from all pods
  inhibit_all_warnings!
  
  # Pods for KPS
  pod 'Moya', '~> 14.0'
  pod 'Toast-Swift', '~> 5.0.1'
  pod 'SnapKit', '~> 5.0.0'
  pod 'DeviceKit', '~> 4.0'
  pod 'Kingfisher', '~> 7.0'
  pod 'SwiftRichString', '~> 3.7.2'
  
  target 'KPSTests' do
    inherit! :complete
  end

end



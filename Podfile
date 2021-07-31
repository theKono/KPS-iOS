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
use_frameworks!
target 'KPS' do
  
  # ignore all warnings from all pods
  inhibit_all_warnings!
  
  # Pods for KPS
  pod 'Moya', '~> 14.0'

  target 'KPSTests' do
    inherit! :complete
  end

end



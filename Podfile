source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

project 'ringoid'

def common_pods
	pod 'RxRealm'
	pod 'RxCocoa'
	pod 'RxAlamofire'
	pod 'RxNuke'
	pod 'Fabric'
	pod 'Crashlytics'
	pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '4.1.0'
	pod 'RxReachability'
	pod 'DeviceKit'
	pod 'Valet'
	pod 'Branch'
	pod 'Firebase/Core'
	pod 'Firebase/Performance'
	pod 'Firebase/Messaging'
	pod 'Flurry-iOS-SDK/FlurrySDK'
	pod 'FBSDKCoreKit'
	pod 'Differ'
end

target 'ringoid' do
	common_pods
end

target 'ringoid st' do
	common_pods
end

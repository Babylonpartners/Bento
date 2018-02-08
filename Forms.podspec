Pod::Spec.new do |s|

  s.name          = "Forms"
  s.version       = "0.1"
  s.summary       = "Component based abstraction on top of UITableView and UICollectionView"

  s.description   = <<-DESC
                    Component-based abstraction on top of UITableView and UICollectionView.  
                    Provides a declarative way to render data in UITableView and UICollectionView
                    DESC

  s.homepage      = "https://github.com/Babylonpartners/FormsKit"
  s.license       = { :type => "MIT", :file => "LICENSE" }
  s.author        = { "Babylon iOS" => "ios.development@babylonhealth.com" }
  s.ios.deployment_target = '9.0'
  s.source        = { :git => "https://github.com/Babylonpartners/FormsKit.git", :tag => "#{s.version}" }
  s.source_files  = 'FormsKit/Forms/*.swift', 'FormsKit/Forms/**/*.swift'

  s.dependency "FlexibleDiff", "~> 0.0.1"
end

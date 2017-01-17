Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "Allihoopa"
  s.version      = "1.0.0"
  s.summary      = "SDK to drop and import pieces to and from Allihoopa."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
Import and drop pieces from and to Allihoopa. Make your app part of the music making!
DESC

  s.homepage     = "https://github.com/allihoopa/Allihoopa-iOS"


  s.license      = { :type => "MIT", :file => "LICENSE" }


  s.authors             = { "mhallin" => "mhallin@fastmail.com" }

  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/allihoopa/Allihoopa-iOS.git", :tag => "#{s.version}" }

  s.source_files  = "Allihoopa", "Allihoopa/Drop"
  s.resource_bundles = {
    "Allihoopa" => ["Allihoopa/Drop/Base.lproj/*.*","Allihoopa/Drop/ja.lproj/*.*"]
  }

  s.dependency 'AllihoopaCore', '~> 0.2.7'
 
end

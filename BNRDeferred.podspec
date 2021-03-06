Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name         = "BNRDeferred"
  s.version      = "2.0.0"
  s.summary      = "Work with values that haven't been determined yet."

  s.description  = <<-DESC
  Deferred is an asynchronous promise-style API that can be used as an
  alternative to the "block callback" pattern. It lets you work with values that
  haven't been determined yet, like an array that's coming later (one day!) from
  a web service call. It was originally inspired by OCaml's Deferred library.
                   DESC

  s.homepage     = "https://github.com/bignerdranch/Deferred"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.license      = "MIT"


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.authors             = {"John Gallagher" => "jgallagher@bignerdranch.com",
                           "Zachary Waldowski" => "zachary@bignerdranch.com",
                           "Brian Hardy" => "brian@bignerdranch.com"}

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.deployment_target     = "8.0"
  s.osx.deployment_target     = "10.10"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target    = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source       = { :git => "https://github.com/bignerdranch/Deferred.git", :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "Sources"
  s.header_dir    = "Deferred"
  s.module_name   = "Deferred"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.requires_arc = true

end

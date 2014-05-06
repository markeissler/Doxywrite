Pod::Spec.new do |s|
  s.name         = "Doxywrite"
  s.version      = "1.1.3"
  s.license      = 'MIT'
  s.authors      = { "Mark Eissler" => "mark@mixtur.com" }
  s.summary      = "Generate and install a DocSet from your Xcode project via Doxygen."
  s.description = <<-DESC
    Generate and install a DocSet from your Xcode project via Doxygen. Doxywrite can be run from the command line or from an Xcode run-script (see README.md for instructions on usage).
  DESC
  s.homepage     = "https://github.com/markeissler/Doxywrite"
  s.source       = { :git => "https://github.com/markeissler/Doxywrite.git", :tag => "mx-#{s.version}" }
  s.preserve_path = ".doxywrite.sh", ".doxywrite-example.cfg"
  s.requires_arc = false
end
# Textmate 1
# app "TextMate", :license => { :key => 'XXX', :name => 'XXX' } do
#   plugin "url_to_plugin"
#   bundle "url_to_bundle"
#   theme "url_to_theme"
# end
source "http://dl-origin.macromates.com/TextMate_1.5.10_r1631.zip"
checksum "4f3f167750b14d6dd1be4e4852f60581a617a47d"
license :preferences, :key => "OakRegistrationLicenseKey", :name => "OakRegistrationOwner"
defaults "com.macromates.textmate"

after_install do
  FileUtils.rm "/usr/local/bin/mate" if File.exists?("/usr/local/bin/mate")
  FileUtils.ln_s "/Applications/TextMate.app/Contents/SharedSupport/Support/bin/mate", "/usr/local/bin/mate"
end

def plugin(source, options = {})
  download source, "~/Library/Application Support/TextMate/PlugIns", options
end

def bundle(source, options = {})
  download source, "~/Library/Application Support/TextMate/Bundles", options
end

def theme(source, options = {})
  download source, "~/Library/Application Support/TextMate/Themes", options
end

def download(source, target, options = {})
  type = case source
  when /^http/
    :http
  when /^git/
    :git
  end
  self.send("download_#{type}", source, target, options)
end

def download_http(source, target, options = {})
  target = File.expand_path(target)
  
  # Prepare target directory
  FileUtils.mkdir_p target
  
  tmp = Tempfile.new File.basename(source)
  system "curl -o '#{tmp.path}' '#{source}'"
  
  if options[:checksum]
    checksum = Digest::SHA1.hexdigest(File.read(tmp.path))
    raise "Checksum mismatch, expected #{options[:checksum]}" if checksum != options[:checksum]
  end
  
  case File.extname(source)[1..-1]
  when "zip"
    system "ditto -x -k '#{tmp.path}' '#{target}'"
  else
    raise "Unknown download type: #{source}"
  end
end

def download_git(source, target, options = {})
  target = File.expand_path(target)

  # Prepare target directory
  FileUtils.mkdir_p target

  options[:name] ||= File.basename(source).gsub(".git", "")
    
  Dir.chdir target do
    system "git clone '#{source}' '#{options[:name]}'"
  end
end

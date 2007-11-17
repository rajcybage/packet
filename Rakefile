require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'
require 'fileutils'
def __DIR__
  File.dirname(__FILE__)
end
include FileUtils

NAME = "packet"
$LOAD_PATH.unshift __DIR__+'/lib'
require 'packet'

CLEAN.include ['**/.*.sw?', '*.gem', '.config']


@windows = (PLATFORM =~ /win32/)

SUDO = @windows ? "" : (ENV["SUDO_COMMAND"] || "sudo")



desc "Packages up Packet."
task :default => [:package]

task :doc => [:rdoc]


Rake::RDocTask.new do |rdoc|
      files = ['README', 'LICENSE', 'CHANGELOG',
               'lib/**/*.rb']
      rdoc.rdoc_files.add(files)
      rdoc.main = 'README'
      rdoc.title = 'Packet Docs'
      rdoc.rdoc_dir = 'doc/rdoc'
      rdoc.options << '--line-numbers' << '--inline-source'
end

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = Packet::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO']
  #s.rdoc_options += RDOC_OPTS + 
  #  ['--exclude', '^(app|uploads)']
  s.summary = "Packet, Events... we got em."
  s.description = s.summary
  s.author = "Hemant"
  s.email = 'foo@bar.com'
  s.homepage = 'http://code.google.com/p/packet/'
  s.required_ruby_version = '>= 1.8.4'

  s.files = %w(LICENSE README Rakefile TODO) + Dir.glob("{bin,spec,lib,examples,script}/**/*") 
      
  s.require_path = "lib"
  s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  #p.need_tar = true
  p.gem_spec = spec
end

task :install do
  sh %{rake package}
  sh %{#{SUDO} gem install pkg/#{NAME}-#{Packet::VERSION} --no-rdoc --no-ri}
end

task :uninstall => [:clean] do
  sh %{#{SUDO} gem uninstall #{NAME}}
end

##############################################################################
# SVN
##############################################################################

desc "Add new files to subversion"
task :svn_add do
   system "svn status | grep '^\?' | sed -e 's/? *//' | sed -e 's/ /\ /g' | xargs svn add"
end


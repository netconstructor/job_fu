# Install hook code here
require 'pathname'

puts IO.read(Pathname.new(__FILE__).dirname.join("README.markdown"))

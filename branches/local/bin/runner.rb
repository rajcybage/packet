require "rubygems"
require "active_support"
require "ostruct"

PACKET_APP = File.expand_path(File.join(File.dirname(__FILE__) + "/.."))
["bin","config","parser","worker","framework","lib"].each { |x| $LOAD_PATH.unshift(PACKET_APP + "/#{x}")}

require "ruby_hacks"
require "packet_guid"
require "disconnect_error"
require "callback"
require "worker_connection"

#require "listener"
require "nbio"
require "worker_delegate"
require "pimp"

require "packet"
require "connection"
require "worker"
require "cpu_worker"

# This file is just a runner of things and hence does basic initialization of thingies required for running
# the application.


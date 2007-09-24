require "rubygems"


PACKET_APP = File.expand_path(File.dirname(__FILE__))
[".","config","parser","worker"].each { |x| $LOAD_PATH.unshift(PACKET_APP + "/../#{x}")}

require "ruby_hacks"
require "listener"

module Packet
  class Reactor
    iattr_accessor :fd_watchlist
    class << self
      def run
        @fd_watchlist ||= []
        t_val = select(@fd_watchlist,nil,nil,0.005)
        unless t_val.blank?
          t_val.each do |b_io|
            next if b_io.blank?
            b_io.each do |t_sock|

            end
          end
        end
      end
    end # end of << self
  end # end of Reactor class
end # end of Packet Class

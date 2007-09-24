require "rubygems"


PACKET_APP = File.expand_path(File.dirname(__FILE__))
[".","config","parser","worker"].each { |x| $LOAD_PATH.unshift(PACKET_APP + "/../#{x}")}

require "ruby_hacks"
#require "listener"
require "nbio_helper"
require "pimp"

module Packet
  # main class which is going to be main worker
  class Reactor
    iattr_accessor :fd_writers, :msg_writers,:msg_reader, :fd_watchlist
    iattr_accessor :listen_sockets
    iattr_accessor :connected_clients

    class << self
      include NbioHelper

      # this function is going to be replaced with epoll implementation and hence it would be a good
      # to keep this as much modular possible.
      def run
        @fd_watchlist ||= []
        yield
        loop do
          accept_connection
          ready_ios = select(@fd_watchlist,nil,nil,0.005)
          next if ready_ios.blank?
          ready_ios = ready_ios.flatten.compact
          ready_ios.each do |t_sock|
            if t_sock.is_a? UNIXSocket
              handle_internal_messages(t_sock)
            else
              handle_external_messages(t_sock)
            end
          end
        end

      end # end of run method

      # handles external TCP socket messages
      def handle_external_messages(t_sock)

      end

      # handles internal unix socket messages
      def handle_internal_messages(t_sock)

      end

      # this function is again going to be replaced with epoll thingy
      def start_server(ip,port,p_module,&block)
        @listen_sockets ||= {}
        @connected_clients ||= {}

        t_socket = Socket.new(AF_INET,SOCK_STREAM,0)
        sockaddr = Socket.sockaddr_in(port.to_i,host)
        t_socket.bind(sockaddr)
        t_socket.listen(50)
        @listen_sockets[t_socket.fileno] = { :socket => t_socket,:block => block,:module => p_module }
      end

      def accept_connection
        @listen_sockets.each do |sock_fd,sock_hash|
          sock_io = sock_hash[:socket]
          begin
            client_socket,client_sockaddr = sock_io.accept_nonblock
          rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
            puts "Not ready yet"
            next
          end
          @fd_watchlist << client_socket
          handler_instance = initialize_server_object(socket[:module])
          sock_hash[:block].call(handler_instance)

          # we should per
          @connected_clients[client_socket.fileno] = { :client_addr => client_sockaddr,:instance => handler_instance }
          handler_instance.post_init
        end

        t_listeners = @listen_sockets.map { |key,value| value[:socket]}
        ready_ios = select(t_listeners,nil,nil,0.005)
        return if ready_ios.blank?
        ready_ios.each do |t_sock|

        end
      end

      def initialize_server_object p_module
        handler =
          if(p_module and p_module.is_a?(Class))
            p_module
          else
            Class.new(Connection) { p_module and include p_module }
          end
        return handler.new
      end

      # method establishes a external connection
      def connect ip,port,p_module

      end

    end # end of << self thing

  end # end of Reactor class
end # end of Packet module

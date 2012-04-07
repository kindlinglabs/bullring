require 'socket'
require 'timeout'

module Bullring
  class Network
    
    def self.is_port_in_use?(ip,port)
      !is_port_open?(ip,port)
    end

    def self.is_port_open?(ip, port)
      begin
        Timeout::timeout(1) do
          begin
            s = TCPSocket.new(ip, port)
            s.close
            return false
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return true
          end
        end
      rescue Timeout::Error
      end

      return true
    end
    
  end
end
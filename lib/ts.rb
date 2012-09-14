require 'rinda/ring'
require 'rinda/tuplespace'
require 'open-uri'

class TupleServer
  def initialize opts

    opts ||= {}
    hostname = `hostname`.chomp
    _uri = opts[:ts] || "druby://0:12345"
    uri = URI(_uri)

    @ts = Rinda::TupleSpace.new
    @place = Rinda::RingServer.new(@ts, uri.port)
    DRb.start_service(_uri, @ts)

    puts "TupleSpace on #{DRb.uri}"

    trap :INT do
      cleanup
      exit 0
    end

    File.write('ts.pid', Process.pid)
    DRb.thread.join
  end

  def cleanup
    File.delete('ts.pid')
  end
end

if $0 == __FILE__
  TupleServer.new
end

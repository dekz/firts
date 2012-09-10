require 'rinda/ring'
require 'rinda/tuplespace'

class TupleServer
  def initialize uri=nil
    uri ||= 'druby://:12345'
    @ts = Rinda::TupleSpace.new
    @place = Rinda::RingServer.new(@ts)
    DRb.start_service(uri, @ts)
    puts "TupleSpace on #{DRb.uri}"
    File.write('ts.pid', Process.pid)
    DRb.thread.join
  end
end

if $0 == __FILE__
  TupleServer.new
end

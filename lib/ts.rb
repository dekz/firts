require 'rinda/ring'
require 'rinda/tuplespace'

$ts = Rinda::TupleSpace.new
place = Rinda::RingServer.new($ts)
DRb.start_service('druby://:12345', $ts)
#DRb.start_service
#DRb.start_service nil, $ts
#provider = Rinda::RingProvider.new :name, :place, DRbObject.new($ts), 'ts'
#provider.provide
puts DRb.uri
File.write('ts.pid', Process.pid)
DRb.thread.join

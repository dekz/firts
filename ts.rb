require 'rinda/tuplespace'

$ts = Rinda::TupleSpace.new
DRb.start_service('druby://:12345', $ts)
puts DRb.uri
File.write('ts.pid', Process.pid)
DRb.thread.join

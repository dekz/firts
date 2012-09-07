# firts

Distributed workers with Tuplespace. Send jobs as procs with arguments (no scope plz).

## Example

   # Do these 3 commands in separate terminals, they block.
   # Start a TupleSpace for everyone to communicate through
   rake ts
   # Start a worker
   rake worker
   # Start a Taskmaster
   rake taskmaster

Send a remote worker a job:

    tm = Taskmaster.new
    tm.run_job('Jacob') do |name|
      puts "Hi there #{name}"
    end

Remote worker will pickup the job and you should see:

    worker::CemHb15DCBzY7Zo connected to #<Rinda::TupleSpace:0x007fe74c82c658>
    worker::CemHb15DCBzY7Zo: Run u1gADFHDXWH2SvJ
    Hi there Jacob
    worker::CemHb15DCBzY7Zo: Done 0

## Overview
Workers listen on TupleSpace for Jobs sent out by Taskmasters. It pulls a job from the list and runs it, posting back to TupleSpace when it's done. You can send over a proc with `Taskmaster#run_job` and pass in args to the proc which will be either Marshalled over to the remote worker or a Reference will be sent when it cannot be marshalled (Files etc).

## Contributing to firts
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012 Jacob Evans. See LICENSE.txt for
further details.


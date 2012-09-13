# firts

Distributed workers with Tuplespace. Send jobs as procs with arguments (no scope plz).

## Example

    # Do these 3 commands in separate terminals, they block.
    # Start a TupleSpace for everyone to communicate through
    firts ts
    # Start a worker
    firts worker
    # Start a Taskmaster
    firts taskmaster

Send a remote worker a job:

    tm = Taskmaster.new
    # See Creating Jobs for creating new jobs
    tm.run_job(job)

Remote worker will pickup the job and you should see:

    worker::CemHb15DCBzY7Zo connected to #<Rinda::TupleSpace:0x007fe74c82c658>
    worker::CemHb15DCBzY7Zo: Run u1gADFHDXWH2SvJ
    Hi there Jacob
    worker::CemHb15DCBzY7Zo: Done 0
    
If you ask Taskmaster for the completed jobs, you should seem something similar to:

    tm.completed_jobs
    # =>[[{
           job => :complete,
           id => "u1gADFHDXWH2SvJ",
           result => {
             :began => 2012-09-11 10:16:14 +1000,
             :end => 2012-09-11 10:16:14 +1000, 
             :worker => "worker::CemHb15DCBzY7Zo", 
             :result => "Hi there Jacob"
           }
        ]]
        
These results are rendered as simple string out puts, whereas most will be reference objects.

## Overview
Workers listen on TupleSpace for Jobs sent out by Taskmasters. It pulls a job from the list and runs it, posting back to TupleSpace when it's done. You can send over a proc with `Taskmaster#run_job` and pass in args to the proc which will be either Marshalled over to the remote worker or a Reference will be sent when it cannot be marshalled (Files etc).

### Selectors
Selectors are a general representation of a construct in TupleSpace. Workers look for certain selectors to find jobs or other actionable items. A Simple selector looks like the following:

    START_TEMPLATE = { 'job' => :start, 'id' => nil, 'run' => nil, }
    STOP_TEMPLATE = { 'job' => :stop, 'id' => nil }
    COMPLETE_TEMPLATE = { 'job' => :complete, 'id' => nil, 'result' => nil }

### Creating Jobs
Jobs can be created (before being published) using `Job::create`.

    job = Job::create({ 'id' => '123abc' }) do |j|
      j.run_task = { 'proc' => Proc.new { |name| puts "Hello #{name}" }, 'args' => 'Fabio' }
    end

Note the useage of strings for keys, this is required in TupleSpace for hash constructs.

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

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
require 'firts'

$options = {
  :ts => 'druby://localhost:1246',
  :server => 'druby://localhost:1246',
}

all_threads = []
tuplespace_thread = Thread.new do
  ts = TupleServer.new $options
end
all_threads << tuplespace_thread

worker_runner = nil
worker_thread = Thread.new do
  wr = WorkerRunner.new $options
  worker_runner = wr
  wr.run
end
all_threads << worker_thread 

while worker_runner.nil?
  sleep 1
end

taskmaster_thread = Thread.new do
  puts "Task master running with #{worker_runner.workers.size} workers"
  workers = worker_runner.workers
  tm = Taskmaster.new $options
  job = Job::create do |job|
    job.run_task = { 'proc' => Proc.new { 'a' } }
  end
  tm.task_list do |j|
    j.job = job
    j.worker = workers[0].id
  end
  puts "Worker #{workers[0].id} should have received the job!"
  puts "Interrupt to exit"
end
all_threads << taskmaster_thread

begin
  all_threads.each { |t| t.join }
rescue Interrupt
  worker_runner.cleanup 
  all_threads.each { |t| t.kill }
end


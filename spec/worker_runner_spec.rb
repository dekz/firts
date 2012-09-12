require 'worker_runner'

describe :worker_runner do
  it "creates the correct amount of workers and cleans them" do
    wr = WorkerRunner.new({ :worker_count => 5,
      "server" => "druby://localhost:12345" 
    })
    workers = wr.instance_variable_get(:@workers)
    workers.size.should == 5
    workers.each do |worker|
      worker.should_receive(:cleanup)
    end
    wr.cleanup
    workers.size.should == 0
  end
end

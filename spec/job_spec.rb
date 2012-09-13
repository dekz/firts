require 'job'
require 'sourcify'

describe :job do
  it "creates a job with an id" do
    job = Job::create 
    job.id.should_not be_nil
  end

  it "creates a job with the id" do
    id = 'abc'
    job = Job::create({ 'id' => id })
    job.id.should == id
  end

  it "creates a job with the id and proc" do
    id = 'abc'
    prc = Proc.new { 'a' }
    job = Job::create({ 'id' => id, 'run' => { 'proc' => prc }})
    job.id.should == id
    job.run_task["proc"].should == prc
  end

  it "creates a job with the id and proc and args" do
    id = 'abc'
    prc = Proc.new { 'a' }
    job = Job::create({ 'id' => id, 'run' => { 'proc' => prc, 'args' => 'test' }})
    job.id.should == id
    job.run_task["proc"].should == prc
    job.run_task["args"].should == 'test'
  end

  it "pass the args on to proc" do
    id = 'abc'
    prc = Proc.new { |a| a }
    #prc = prc.to_source
    job = Job::create({ 'id' => id, 'run' => { 'proc' => prc, 'args' => 'test' }})
    job.id.should == id
    job.run_task["proc"].should == prc
    job.run_task["args"].should == 'test'
    job.exec_proc 'test', prc
    job.result.should == 'test'
  end
end

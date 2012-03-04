require_relative '../spec_helper'

describe Guard::Xcoder do
  let(:subject) { Guard::Xcoder }
  let(:project_name) { "TestProject" }
  
  before do
    Guard.stub_chain(:listener, :directory).and_return(Dir.pwd)
  end
  
  context "when created without any options" do
    let(:subject) { Guard::Xcoder.new }
    
    its(:default_builder_actions) { should eq [ :build ] }
    its(:default_paths) { should eq [ '.' ]}
  end

  context "when no watchers are specified" do
    let(:watchers) { [] }
    
    it "should not generate any file watchers" do
      subject.any_instance.should_not_receive(:create_guard_for)
      subject.new watchers
    end
  end

  context "when the watcher specifed does not match any project" do
    
    let(:watchers) { [ Guard::Watcher.new("UnknownProject") ] }
    
    it "should not generate any file watchers" do
      subject.any_instance.should_not_receive(:create_guard_for)
      subject.new watchers
    end
  end

  context "when the watcher specified matches a project" do
    
    let(:watchers) { [ Guard::Watcher.new("TestProject") ] }

    it "should generate a watcher for all the files in the project" do
      subject.any_instance.should_receive(:create_guard_for).exactly(7).times
      subject.new watchers
    end
  end

  context "when a watcher specified matches the target of a project" do
    
    context "first target" do
      let(:watchers) { [ Guard::Watcher.new("TestProject//Specs") ] }
      
      it "should generate a watcher for all the files in the project" do
        subject.any_instance.should_receive(:create_guard_for).exactly(1).times
        subject.new watchers
      end
    end 
        
    context "second target" do
      let(:watchers) { [ Guard::Watcher.new("TestProject//TestProject") ] }
      
      it "should generate a watcher for all the files in the project" do
        subject.any_instance.should_receive(:create_guard_for).exactly(3).times
        subject.new watchers
      end
    end

   
  end
end

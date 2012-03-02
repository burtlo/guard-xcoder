require_relative '../spec_helper'

describe Guard::Xcoder do
  
  let(:project_name) { "TestProject" }
  let(:target_name) { "TestTarget" }
  
  its(:default_builder_actions) { should eq [ :build ] }
  its(:default_paths) { should eq [ '.' ]}

  describe "#file_watchers_for_project_watchers" do

    let(:given_watchers) { subject.file_watchers_for_project_watchers(original_watchers) }
    
    context "when given no watchers" do

      let(:original_watchers) { [] }
      let(:expected_watchers) { [] }
      
      it "should return an empty list of watchers" do
        given_watchers.should eq expected_watchers
      end
    end

    context "when given a watcher for a single project" do
      context "when no project matches the specified project name" do

        let(:original_watchers) { [ Guard::Watcher.new("Unknown Project") ] }
        let(:expected_watchers) { [] }
          
        it "should return an empty list of watchers" do
          given_watchers.should eq expected_watchers 
        end
          
      end

      context "when a project matches the specified project name" do
        
        before do
          # insert project stub that matches the name - project.name
          # insert targets - project.targets
          # insert source  - target.sources_build_phase.build_phases
          # for each file we need - file.path
        end
        
        let(:original_watchers) { [ Guard::Watcher.new(project_name) ] }
        let(:expected_watchers) do
          []
        end
        
        it "should return a list of new watchers for all files within the project" do
          given_watchers.should eq expected_watchers 
        end
          
      end
    
    end

    context "when given a watchers for a project's target" do
      
      let(:project_target_name) { "#{project_name}//#{target_name}" }
      let(:watchers) { [ Guard::Watcher.new(project_target_name) ] }
      
    end

    context "when given multiple watchers" do

    end
    
  end
end

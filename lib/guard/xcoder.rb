require 'guard'
require 'guard/guard'
require 'xcoder'

module Guard
  class Xcoder < Guard
  
    VERSION = '0.1.0'
    
    def default_builder_actions
      [ :build ]
    end
    
    def default_paths
      [ '.' ]
    end
    
    def initialize(watchers=[], options = {})
      @options = {
        :actions => default_builder_actions,
        :paths => default_paths,
      }.update(options)
 
      @paths = @options[:paths]
      file_watchers = file_watchers_for_project_watchers watchers
      watchers.replace file_watchers
      
      super
    end

    def start
      projects
      UI.info "[Guard::Xcoder] is now monitoring #{projects.map {|p| p.name }.join(", ")}"
    end

    def run_all
      
      projects.each do |project|
        project.targets.each do |target|
          config = target.config('Debug')
          UI.info(("*" * 80))
          UI.info "Building #{project.name} - #{target.name} - #{config.name}"
          UI.info(("*" * 80))
          config.builder.build
        end
      end
      
    end
   
    # 
    # @param [Array<String>] commands to execute
    #
    def run_on_change(commands)
      
      project_name, target_name, config_name = commands.first.split("//")
      builder = Xcode.project(project_name).target(target_name).config(config_name).builder

      UI.info "[Guard::Xcoder] Performing [ #{@options[:actions].join(", ")} ] for #{project_name} > #{target_name} > #{config_name}"

      Array(@options[:actions]).each do |operation|
        builder.send(operation)
      end
      
    end

    def projects
      @project ||= begin
        # TODO: projects found multiple times will be duplicated.
        @paths.map {|path| Xcode.find_projects path }.flatten.compact
      end
    end
    
    #
    # @param [Array<Watcher>] watchers the existing watchers defined within the Guardfile that specify the path the project, target,
    #   and config.
    # @return [Array<Watcher>] a new list of watchers for every file within the matching project > target. Each watcher when matched
    #   will return a path to the project//target//config that needs to be built.
    # 
    def file_watchers_for_project_watchers(watchers)

      watchers.map do |watcher|
        watchers_for_source_files_in(watcher.pattern)
      end.flatten.compact

    end
    
    def watchers_for_source_files_in pattern
      
      targets_in_path(pattern).map do |target|
        
        # TODO: this is currently hard-coded to Debug configuration, though the user can specify Release
        
        build_action = lambda { "#{target.project.name}//#{target.name}//Debug" }
        
        project_root_dir = File.join(File.dirname(target.project.path), target.name)
        
        # Create a watcher for all source build files specified within the target
        
        new_guards = target.sources_build_phase.build_files.map do |file|
          full_source_path = File.join(project_root_dir,file.path)
          puts "Source Path: #{full_source_path}"
          create_guard_for full_source_path, build_action
        end
        
        # Create a watcher for the pch if one has been specified.
        if target.config('Debug').prefix_header
          prefix_header_path = File.join(File.dirname(target.project.path), target.config('Debug').prefix_header)
          puts prefix_header_path
          new_guards << create_guard_for(prefix_header_path, build_action)
        end

        new_guards
        
      end.flatten.compact
      
    end

    def targets_in_path(pattern)

      project_name, target_name, config_name = pattern.split("//")
      projects.find_all {|project| project.name == project_name }.map do |project|
        if target_name
          project.targets.find_all {|target| target.name == target_name }
        else
          project.targets
        end
      end.flatten.compact

    end

    def create_guard_for full_source_path, command
      relative_source_path = full_source_path.gsub("#{::Guard.listener.directory}/",'')

      # Given a file that is meant for the sources build phase, it
      # is likely that the file has an accompanying header file so
      # we expand the pattern to include that.
      
      source_regex = Regexp.new( Regexp.escape(relative_source_path).to_s.gsub(/(?:m?m)$/,'(?:m?m|h)') )
      ::Guard::Watcher.new(source_regex,command)
    end
  end
end

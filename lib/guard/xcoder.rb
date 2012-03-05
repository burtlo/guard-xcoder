require 'guard'
require 'guard/guard'
require 'xcoder'

module Guard
  class Xcoder < Guard
  
    VERSION = '0.1.0'
    
    #
    # By default when a file has changed the builder should build the target.
    # 
    # @return [Array<Symbol,String>] a list of the default methods that will
    #   be executed with the builder object that is found when the appropriate
    #   file has changed.
    def default_builder_actions
      [ :build ]
    end
    
    #
    # By default return the current working directory.
    # 
    # @note while this is configurable there will likely be some bizarre complications
    #   unless the path of the guard is also changed as it usually only notifies
    #   upon changes that were made locally within the directory and sub-directories.
    #
    # @return [Array<String>] the paths that should be searched for projects.
    # 
    def default_paths
      [ '.' ]
    end
    
    #
    # 
    # @param [Array<Guard::Watcher>] watchers the list of watchers defined in the Guardfile.
    #   Usually the watchers define a file name or file regex pattern. For xcoder-guard this
    #   should be the names of the projects/targets.
    # 
    # @param [Hash] options addition options to override the default options.
    # 
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

    #
    # Runs all the projects that were found in the projects list and builds all their targets.
    # @todo this should likely limited only to the projects/targets specified in the watchers.
    # 
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
    # This is called when a file has changed within a project/target. The commands
    # sent to this method is a path to the builder object that should be generated.
    # 
    # The builder that is generated will perform all the default actions or the actions
    # defined in the options specified.
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

    #
    # @return [Array<Project>] a list of all the projects found within the specified paths
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
    
    #
    # Find all the files relevant to the specified file pattern and generate
    # new watchers out of them.
    # 
    # @example project -> target -> config
    # 
    #     "TestProject//FirstTarget//Release"
    # 
    def watchers_for_source_files_in pattern
      
      project_name, target_name, config_name = pattern.split("//")
      
      # @todo assuming the project has the 'Debug' config when the project should likely be asked.
      
      config_name ||= "Debug"
      
      targets_for(project_name,target_name).map do |target|
        
        build_action = lambda { "#{target.project.name}//#{target.name}//#{config_name}" }
        
        project_root_dir = File.join(File.dirname(target.project.path), target.name)
        
        # Create a watcher for all source build files specified within the target
        
        new_guards = target.sources_build_phase.build_files.map do |file|
          full_source_path = File.join(project_root_dir,file.path)
          puts "Source Path: #{full_source_path}"
          create_guard_for full_source_path, build_action
        end
        
        # Create a watcher for the pch if one has been specified.
        
        if target.config(config_name).prefix_header
          prefix_header_path = File.join(File.dirname(target.project.path), target.config(config_name).prefix_header)
          puts prefix_header_path
          new_guards << create_guard_for(prefix_header_path, build_action)
        end

        new_guards
        
      end.flatten.compact
      
    end

    def targets_in_path(project_name,target_name)

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

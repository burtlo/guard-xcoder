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
        matching_projects = projects.find_all {|project| project.name == watcher.pattern }
        
        matching_projects.map do |project|
          project.targets.map do |target|
            
            build_action = lambda { "#{project.name}//#{target.name}//Debug" }
            
            target.sources_build_phase.build_files.map do |file|
              project_root_dir = File.join File.dirname(project.path), project.name
              source_file_path = File.join(project_root_dir,file.path).gsub("#{::Guard.listener.directory}/",'')
              
              puts "Building watcher for file: #{source_file_path}"
              
              watcher = ::Guard::Watcher.new(source_file_path,build_action)
              watcher

            end
          end
        end.flatten.compact.uniq
        
      end.flatten

    end

  end
end

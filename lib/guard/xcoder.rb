require 'guard'
require 'guard/guard'
require 'xcoder'

module Guard
  class Xcoder < Guard
  
    VERSION = '0.1.0'
    
    def initialize(watchers=[], options = {})
      @options = {
        :actions => [ :build ],
        :paths => [ '.' ],
      }.update(options)
 
      @builders = {}
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
      
      puts "going to perform :#{@options[:actions]} for #{commands}"
      
      Array(@options[:actions]).each do |operation|
        @builders[commands.first].send(operation)
      end
      
    end

    private

    def projects
      @project ||= begin
        # TODO: projects found multiple times will be duplicated.
        @paths.map {|path| Xcode.find_projects path }.flatten.compact
      end
    end

    def file_watchers_for_project_watchers(watchers)

      watchers.map do |watcher|
        matching_projects = projects.find_all {|project| project.name == watcher.pattern }
        
        matching_projects.map do |project|
          project.targets.map do |target|
            
            source_file_builder = target.config('Debug').builder
            
            target.sources_build_phase.build_files.map do |file|
              project_root_dir = File.join File.dirname(project.path), project.name
              source_file_path = File.join(project_root_dir,file.path).gsub("#{::Guard.listener.directory}/",'')
              
              puts "Building watcher for file: #{source_file_path}"
              
              @builders[source_file_path] = source_file_builder
              watcher = ::Guard::Watcher.new(source_file_path)
              watcher
            end
          end
        end.flatten.compact.uniq
        
      end.flatten

    end

  end
end

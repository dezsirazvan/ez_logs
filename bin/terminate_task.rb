#!/usr/bin/env ruby

# EZLogs Rails Application - Task Termination Script
# Moves completed tasks from active/ to done/ folder

require 'fileutils'
require 'optparse'

class TaskTerminator
  def initialize
    @base_dir = File.expand_path('../ai_tasks', __FILE__)
    @active_dir = File.join(@base_dir, 'active')
    @done_dir = File.join(@base_dir, 'done')
    @options = {}
  end

  def run
    parse_options
    validate_environment
    
    if @options[:list]
      list_active_tasks
    elsif @options[:task]
      terminate_task(@options[:task])
    else
      show_help
    end
  end

  private

  def parse_options
    OptionParser.new do |opts|
      opts.banner = "Usage: terminate_task [options]"

      opts.on("-t", "--task TASK", "Task number to terminate (e.g., 01, 02)") do |task|
        @options[:task] = task
      end

      opts.on("-l", "--list", "List all active tasks") do
        @options[:list] = true
      end

      opts.on("-h", "--help", "Show this help message") do
        show_help
        exit
      end
    end.parse!
  end

  def validate_environment
    unless Dir.exist?(@active_dir)
      puts "❌ Error: Active tasks directory not found at #{@active_dir}"
      exit 1
    end

    FileUtils.mkdir_p(@done_dir) unless Dir.exist?(@done_dir)
  end

  def list_active_tasks
    tasks = Dir.glob(File.join(@active_dir, '*')).select { |f| File.directory?(f) }
    
    if tasks.empty?
      puts "📋 No active tasks found."
      return
    end

    puts "📋 Active Tasks:"
    puts "=" * 50
    
    tasks.sort.each do |task_dir|
      task_name = File.basename(task_dir)
      instructions_file = File.join(task_dir, 'Instructions.md')
      feature_file = File.join(task_dir, 'Feature.md')
      
      status = []
      status << "📝 Instructions" if File.exist?(instructions_file)
      status << "🎯 Features" if File.exist?(feature_file)
      
      puts "#{task_name}: #{status.join(', ')}"
    end
  end

  def terminate_task(task_number)
    task_pattern = File.join(@active_dir, "#{task_number}-*")
    task_dirs = Dir.glob(task_pattern)
    
    if task_dirs.empty?
      puts "❌ Error: No task found matching pattern #{task_pattern}"
      exit 1
    end
    
    if task_dirs.length > 1
      puts "⚠️  Multiple tasks found:"
      task_dirs.each { |dir| puts "  - #{File.basename(dir)}" }
      puts "Please specify the exact task name."
      exit 1
    end
    
    task_dir = task_dirs.first
    task_name = File.basename(task_dir)
    done_task_dir = File.join(@done_dir, task_name)
    
    # Check if task is ready for termination
    instructions_file = File.join(task_dir, 'Instructions.md')
    feature_file = File.join(task_dir, 'Feature.md')
    
    unless File.exist?(instructions_file) && File.exist?(feature_file)
      puts "❌ Error: Task #{task_name} is missing required files:"
      puts "  - Instructions.md: #{File.exist?(instructions_file) ? '✅' : '❌'}"
      puts "  - Feature.md: #{File.exist?(feature_file) ? '✅' : '❌'}"
      exit 1
    end
    
    # Move task to done folder
    begin
      FileUtils.mv(task_dir, done_task_dir)
      puts "✅ Task #{task_name} successfully terminated and moved to done/"
      puts "📁 Location: #{done_task_dir}"
    rescue => e
      puts "❌ Error moving task: #{e.message}"
      exit 1
    end
  end

  def show_help
    puts <<~HELP
      EZLogs Rails Application - Task Termination Script
      
      Usage: terminate_task [options]
      
      Options:
        -t, --task TASK     Terminate specific task (e.g., 01, 02)
        -l, --list          List all active tasks
        -h, --help          Show this help message
      
      Examples:
        terminate_task -l                    # List all active tasks
        terminate_task -t 01                 # Terminate task 01
        terminate_task --task 02-project-setup # Terminate specific task
      
      The script will:
      1. Validate the task has both Instructions.md and Feature.md
      2. Move the task from active/ to done/ folder
      3. Provide confirmation of the operation
    HELP
  end
end

if __FILE__ == $0
  TaskTerminator.new.run
end 
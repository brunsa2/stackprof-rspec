# frozen_string_literal: true

require 'rspec/core'
require 'json'
require 'stackprof'

# TODO: default to pass to stackprof settings

module StackprofRspec
  def self.configuration
    @configuration ||= StackprofRspec::Configuration.new
  end

  def self.configure
    yield configuration if block_given?
  end

  class Configuration

  end
end

RSpec.configure do |config|
  name = ""
  name_used = false
  e = nil
  need_to_stop = false

  # If running on begin, don't start, and don't stop
  # If not running on begin, and we should, start, and stop it
  # If running on stop

  config.before do |example|
    e = example

    if example.metadata[:profile]
      disabled = example.metadata[:profile].respond_to?(:[]) && example.metadata[:profile][:disabled]
      new_name = example.metadata[:profile].respond_to?(:[]) && example.metadata[:profile][:name]

      puts "Before, name: #{name}"

      unless disabled || StackProf.running?
        if name != new_name
          if name_used
            puts "Results written"
            profile = StackProf.results
            File.write('stackprof.json', JSON.generate(profile))
          end
          name = new_name
          name_used = false
        end

        puts "Starting profiling"
        StackProf.start(mode: :cpu, raw: true)
        need_to_stop = true
        name_used = true
      end
    end
  end

  config.after do |example|
    if need_to_stop
      puts "Stopping profiling"
      StackProf.stop
      need_to_stop = false
    end

    puts "After, name: #{name}"
    puts
  end

  config.after(:suite) do
    if name_used
      puts "Results written"
      profile = StackProf.results
      File.write('stackprof.json', JSON.generate(profile))
    end
  end
end

# default group name (file name) is provided
# example may choose a group name
# every time the group name changes, a results file is emitted (except when changing from the default name and no test has run yet)

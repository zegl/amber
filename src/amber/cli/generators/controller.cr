require "file_utils"
require "./field.cr"

module Amber::CLI
  class Controller < Teeplate::FileTree
    include Amber::CLI::Helpers
    directory "#{__DIR__}/../templates/controller"
    private getter language

    @name : String
    @actions = Hash(String, String).new
    getter language : String = CLI.config.language

    def initialize(@name, actions)
      parse_actions(actions)
      add_routes :web, <<-ROUTES
        #{@actions.map { |action, verb| %Q(#{verb} "/#{@name}/#{action}", #{class_name}Controller, :#{action}) }.join("\n    ")}
      ROUTES
      add_views
    end

    def parse_actions(actions)
      actions.each do |action|
        next unless action.size > 0
        split_action = action.split(":")
        @actions[split_action.first] = split_action[1]? || "get"
      end
    end

    def add_views
      @actions.each do |action_name, _|
        FileUtils.mkdir_p("src/views/#{@name}")
        File.touch("src/views/#{@name}/#{action_name}.#{language}")
      end
    end
  end
end

module Amber::CLI
  class_property color = true

  class MainCommand < ::Cli::Supercommand
    command "g", aliased: "generate"

    class Generate < Command
      class Options
        arg "type", desc: "scaffold, api, model, controller, migration, mailer, socket, channel, error", required: true
        arg "name", desc: "name of resource", required: false
        arg_array "fields", desc: "user:reference name:string body:text age:integer published:bool"
        bool "--no-color", desc: "Disable colored output", default: false
        help
      end

      class Help
        header "Generates application based on templates"
        caption "# Generates application based on templates"
      end

      def run
        CLI.toggle_colors(options.no_color?)
        ensure_name_argument!
        template = Template.new(args.name, ".", args.fields)
        template.generate args.type
      end

      private def ensure_name_argument!
        unless args.name?
          error "Parsing Error: The NAME argument is required."
          exit! help: true, error: true
        end
      end

      class Help
        caption "# Generate Amber classes"
      end
    end
  end
end

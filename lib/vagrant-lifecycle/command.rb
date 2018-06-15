module VagrantPlugins
  module Lifecycle
    class Command < Vagrant.plugin(2, :command)
      def self.synopsis
        "provisions the vagrant machine using a custom lifecycle event"
      end

      # Like OptionParser.order!, but leave any unrecognized --switches alone
      def order_recognized!(parser, args)
        extra_opts = []
        begin
          parser.order!(args) {|a| extra_opts << a}
        rescue OptionParser::InvalidOption => e
          extra_opts << e.args[0]
          retry
        end
        args[0, 0] = extra_opts
      end

      def execute
        options = Hash.new
        opt_parser = OptionParser.new do |parser|
          parser.on("-e", "--event EVENT", "Lifecycle event to execute") do |p|
            options[:event] = p
          end
          order_recognized!(parser, ARGV)
        end
        opt_parser.program_name="vagrant lifecycle"

        unless options.key?(:event)
          @env.ui.error "Lifecycle event parameter missing!"
          puts opt_parser.help
          exit 1
        end
        lifecycle_event = options[:event]

        with_target_vms([], reverse: true) do |machine|
          machine.action(:provision, {:lifecycle_event => lifecycle_event})
        end

        exit 0
      end
    end
  end
end

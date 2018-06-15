module VagrantPlugins
  module Lifecycle
    class MiddleWare
      def initialize(app, env)
        @app = app

        klass = self.class.name.downcase.split('::').last
        @logger = Log4r::Logger.new("vagrant::lifecycle::#{klass}")
      end

      def call(env)
        event = env[:lifecycle_event] || env[:machine].config.lifecycle.default_event || nil

        if event.nil?
          @app.call(env)
        else
          chef_provisioners = env[:machine].config.vm.provisioners.select do |provisioner|
            # Vagrant 1.7 changes provisioner.name to provisioner.type
            if provisioner.respond_to? :type
              provisioner.type.to_sym == :chef_solo || provisioner.type.to_sym == :chef_client || provisioner.type.to_sym == :chef_zero
            else
              provisioner.name.to_sym == :chef_solo || provisioner.name.to_sym == :chef_client || provisioner.name.to_sym == :chef_zero
            end
          end

          # @type [Hash]
          lifecycle_events = env[:machine].config.lifecycle.events

          if lifecycle_events.key?(event) || lifecycle_events.key?(event.to_sym) || lifecycle_events.key?(event.to_s)
            # @type [lambda]
            event_lambda = lifecycle_events[event] || lifecycle_events[event.to_sym] || lifecycle_events[event.to_s]

            chef_provisioners.each do |chef|
              begin
                new_run_list = event_lambda.call(chef.config.run_list || [], env)
                @logger.debug "Setting run_list = #{new_run_list.inspect}"

                if new_run_list.kind_of?(Array)
                  chef.config.run_list = new_run_list
                else
                  env[:ui].error "Could not evaluate proper run list for the lifecycle event #{event}!"
                  env[:interrupted] = true
                end
              rescue Exception => e
                env[:ui].error "Failed while evaluating run list for the event #{event} with error: #{e}"
                env[:interrupted] = true
              end
            end
          else
            env[:ui].error "Lifecycle event #{event} not configured!"
            env[:interrupted] = true
          end

          @app.call(env)
        end
      end
    end
  end
end

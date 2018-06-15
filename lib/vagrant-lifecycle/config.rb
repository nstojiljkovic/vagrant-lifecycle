require 'vagrant/util/hash_with_indifferent_access'

module VagrantPlugins
  module Lifecycle
    class Config < Vagrant.plugin("2", :config)
      MAYBE = Object.new.freeze

      # Lifecycle events configuration.
      # @return [Hash]
      attr_accessor :events

      # Override default provision
      # @return [Symbol]
      attr_accessor :default_event

      def initialize
        super

        @default_event = nil
        @events = Hash.new

        @__finalized = false
      end

      def finalize!
        @__finalized = true
      end

      def validate(machine)
        errors = _detected_errors

        unless @default_event.nil?
          unless @events.key?(@default_event) || @events.key?(@default_event.to_s) || @events.key?(@default_event.to_sym)
            errors << "#{@default_event} event configuration not found!"
          end
        end

        if @events.is_a?(Hash)
          @events.each do |k, v|
            if v.respond_to? :call
              unless v.arity == 2
                errors << "#{k} event configuration is expected to be lambda with 2 arguments!"
              end
            else
              errors << "#{k} event configuration is expected to be lambda!"
            end
          end
        else
          errors << "events configuration is expected to be a hash!"
        end

        {
            "Lifecycle" => errors
        }
      end

      def to_hash
        raise "Must finalize first." if !@__finalized

        {
            default_event: @default_event,
            events: @events
        }
      end

      def missing?(obj)
        obj.to_s.strip.empty?
      end
    end
  end
end

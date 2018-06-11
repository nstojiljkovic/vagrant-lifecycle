require "vagrant-lifecycle/version"

require 'json'

module VagrantPlugins
  module Lifecycle
    class Command < Vagrant.plugin(2, :command)
      def self.synopsis
        "Lifecycle..."
      end

      def execute
        MiddleWareConfig.instance.enabled = true

        with_target_vms([], reverse: true) do |machine|
          machine.action(:provision)
        end

        exit 0
      end
    end
  end
end

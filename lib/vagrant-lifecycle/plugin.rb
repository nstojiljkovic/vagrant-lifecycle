require "vagrant-lifecycle/command"
require "vagrant-lifecycle/middleware"
require "vagrant-lifecycle/version"

require 'json'

module VagrantPlugins
  module Lifecycle
    class Plugin < Vagrant.plugin(2)
      name "Lifecycle Plugin"

      def self.provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use MiddleWare
        end
      end

      [:machine_action_up, :machine_action_reload, :machine_action_provision].each do |action|
        action_hook(:lifecycle_provision, action) do |hook|
          # hook.after(Vagrant::Action::Builtin::ConfigValidate, Plugin.provision_init)
          hook.before(Vagrant::Action::Builtin::Provision, Plugin.provision)
        end
      end

      command "lifecycle" do
        Command
      end

      config(:lifecycle) do
        require_relative "config"
        Config
      end
    end
  end
end

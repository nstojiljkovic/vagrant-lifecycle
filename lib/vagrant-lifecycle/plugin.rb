require 'vagrant-lifecycle/command'
require 'vagrant-lifecycle/config'
require 'vagrant-lifecycle/version'

module VagrantPlugins
  module Lifecycle
    class Plugin < Vagrant.plugin(2)
      name 'Lifecycle Plugin'

      [:machine_action_up, :machine_action_reload, :machine_action_provision].each do |action|
        action_hook(:lifecycle_provision, action) do |hook|
          hook.before(Vagrant::Action::Builtin::Provision, Action::EvalLifecycleRunList)
        end
      end

      command 'lifecycle' do
        Command
      end

      config(:lifecycle) do
        require_relative 'config'
        Config
      end
    end
  end
end

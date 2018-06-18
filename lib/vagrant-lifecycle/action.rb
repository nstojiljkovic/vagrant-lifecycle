require "pathname"

module VagrantPlugins
  module Lifecycle
    module Action
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :EvalLifecycleRunList, action_root.join("eval_lifecycle_run_list")
    end
  end
end
# Vagrant Lifecycle Plugin

Vagrant Lifecycle is a Vagrant plugin that allows execution of custom provisioning events for the Chef provisioners.

The primarily goal of this plugin is to ease the development and testing of Chef recipes intended for use on services
like AWS OpsWorks.

## Installation

1. Install the latest version of [Vagrant](https://www.vagrantup.com/downloads.html)
2. Install the Vagrant Lifecycle plugin:

  ```sh
  $ vagrant plugin install vagrant-lifecycle
  ```

## Usage

Example Vagrantfile configuration section for Vagrant Lifecycle:

```ruby
Vagrant.configure("2") do |config|
  # Default lifecycle event. 
  # If set, the vagrant-lifecycle with alter the default vagrant provision run list.
  config.lifecycle.default_event = :setup

  # Lifecycle events configuration hash.
  # Each event needs a lambda with 2 parameters run_list and env and should return the new run list
  # Parameter env is vagrant-lifecycle plugin's middleware environment hash with various interesting keys:
  # * env[:ui] is an instance of ::Vagrant::UI::Interface
  # * env[:machine] is an instance of ::Vagrant::Machine etc.
  config.lifecycle.events = {
     :configure => lambda {|run_list, env|
       run_list + ["recipe[sample_cookbook::configure]"]
     },
     :deploy => lambda {|run_list, env|
       run_list + ["recipe[sample_cookbook::deploy]"]
     },
     :setup => lambda {|run_list, env|
       run_list + ["recipe[sample_cookbook::setup]"]
     }
  }
end
```

If you have configured the default_event, it will be run when you run provision the usual way:

```bash
$ vagrant provision
```

You can execute provisioning on the specific lifecycle event via command (for example for deploy event):

```bash
$ vagrant lifecycle -e deploy
```

### Usage with other Vagrant plugins

Currently executed lifecycle event name is available in other Vagrant plugin's middlewares through `:lifecycle_event` 
key of the environment hash. Please note that this key will not be set during regular provision even if the
`lifecycle.default_event` is configured.

### More examples

#### Evaluate run list based on lifecycle event and node roles 

Example Vagrantfile configuration section:

```ruby
# Required for $LAST_MATCH_INFO used bellow
require "English"

Vagrant.configure("2") do |config|
  config.lifecycle.events = {
     :configure => lambda {|run_list, env|
       run_list.flat_map {|r|
         case r
         when /^role\[(?<role>.*)\]/
           %W(role[#{$LAST_MATCH_INFO['role']}] recipe[layer_#{$LAST_MATCH_INFO['role']}::configure])
         else
           [r]
         end
       }
     },
     :deploy => lambda {|run_list, env|
       run_list.flat_map {|r|
         case r
         when /^role\[(?<role>.*)\]/
           %W(role[#{$LAST_MATCH_INFO['role']}] recipe[layer_#{$LAST_MATCH_INFO['role']}::configure] recipe[layer_#{$LAST_MATCH_INFO['role']}::deploy])
         else
           [r]
         end
       }
     },
     :setup => lambda {|run_list, env|
       run_list.flat_map {|r|
         case r
         when /^role\[(?<role>.*)\]/
           %W(role[#{$LAST_MATCH_INFO['role']}] recipe[layer_#{$LAST_MATCH_INFO['role']}::setup])
         else
           [r]
         end
       }
     }
  }
end
```

#### Require additional parameter(s) for a specific lifecycle event

Example Vagrantfile configuration section:

```ruby
# Required for $LAST_MATCH_INFO used bellow
require "English"

Vagrant.configure("2") do |config|
  config.lifecycle.events = {
    :deploy => lambda {|run_list, env|
      options = {}
      opt_parser = OptionParser.new do |parser|
        parser.on("-a", "--application APPLICATION", "Application to deploy") do |p|
          options[:application] = p
        end
        parser.parse!
      end
      opt_parser.program_name="vagrant lifecycle -e deploy"

      if options.empty?
        puts opt_parser.help
        exit 1
      end

      unless options.key?(:application)
        env[:ui].error "Application parameter missing!"
        exit 1
      end

      run_list.flat_map {|r|
        case r
        when /^role\[(?<role>.*)\]/
          %W(role[#{$LAST_MATCH_INFO['role']}] recipe[layer_#{$LAST_MATCH_INFO['role']}::configure] recipe[layer_#{$LAST_MATCH_INFO['role']}::deploy_#{options[:application]}])
        else
          [r]
        end
      }
    }        
  }
end
```

Sample usage:

```bash
$ vagrant lifecycle -e deploy -a really_cool_app
```

#### Use specific machine info

Example Vagrantfile configuration section:

```ruby
Vagrant.configure("2") do |config|
  config.lifecycle.events = {
     :configure => lambda {|run_list, env|
       run_list + ["recipe[sample_cookbook::configure]"]
     },
     :deploy => lambda {|run_list, env|
       if env[:machine].name.to_s == "node1"
         run_list + ["recipe[sample_cookbook::deploy]"]
       else
         run_list
       end
     },
     :setup => lambda {|run_list, env|
       run_list + ["recipe[sample_cookbook::setup]"]
     }
  }
end
```
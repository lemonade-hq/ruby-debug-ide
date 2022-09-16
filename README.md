[![CI](https://github.com/corgibytes/ruby-debug-ide/actions/workflows/ci.yml/badge.svg)](https://github.com/corgibytes/ruby-debug-ide/actions/workflows/ci.yml)
[![Release Notes](https://github.com/corgibytes/ruby-debug-ide/actions/workflows/release-notes.yml/badge.svg)](https://github.com/corgibytes/ruby-debug-ide/actions/workflows/release-notes.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

# ruby-debug-ide

The ruby-debug-ide gem provides the protocol to establish communication between the debugger engine (such as [debase](https://rubygems.org/gems/debase) or [ruby-debug-base](https://rubygems.org/gems/ruby-debug-base)) and IDEs (for example, [RubyMine](https://www.jetbrains.com/ruby/), [Visual Studio Code](https://code.visualstudio.com/), or [Eclipse](https://www.eclipse.org/ide/)). ruby-debug-ide redirects commands from the IDE to the debugger engine. Then, it returns answers/events received from the debugger engine to the IDE. To learn more about a communication protocol, see the following document: [ruby-debug-ide protocol](protocol-spec.md).

Forked to add support for Docker containers.  See the below issues for more information:

- [#107](https://github.com/ruby-debug/ruby-debug-ide/issues/107) - Docker debugging and sub-debugger with random port
- [#186](https://github.com/ruby-debug/ruby-debug-ide/issues/186) - Error Raised when Debugging a Multi-Process app in Docker on a Mac

## Install

Depending on the used Ruby version you will need the following additional gems installed:

- Ruby 2.x - [debase](https://rubygems.org/gems/debase)

    ```ruby
    group :development, :test do
      gem "ruby-debug-ide", git: "https://github.com/corgibytes/ruby-debug-ide", tag: "v0.7.100.rc1"
      gem "debase"
    end
    ```

- Ruby 1.9.x - [ruby-debug-base19x](https://rubygems.org/gems/ruby-debug-base19x)

    ```ruby
    group :development, :test do
      gem "ruby-debug-ide", git: "https://github.com/corgibytes/ruby-debug-ide", tag: "v0.7.100.rc1"
      gem "ruby-debug-base19x"
    end
    ```

- jRuby or Ruby 1.8.x - [ruby-debug-base](https://rubygems.org/gems/ruby-debug-base)

    ```ruby
    group :development, :test do
      gem "ruby-debug-ide", git: "https://github.com/corgibytes/ruby-debug-ide", tag: "v0.7.100.rc1"
      gem "ruby-debug-base"
    end
    ```

For Windows, make sure that the Ruby [DevKit](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit) is installed.
  
## Using the debugger

There are several different ways to use the ruby-debug-ide gem depending on the IDE you are using and if you are running your application in a container.  Below are some of the setups that we have used succssefully.  If your setup is not mentioned please let us know by opening a [issue](https://github.com/corgibytes/ruby-debug-ide/issues) or [pull request](https://github.com/corgibytes/ruby-debug-ide/pulls).

No matter your setup need to make sure the following ports are open:

- 1234 - Default port that ruby-debug-ide listens on.
- 58430-58450 - Only required if your application spawns subprocesses.  For example, debugging Rails applications that use [Passenger](https://www.phusionpassenger.com/) or [Unicorn](https://yhbt.net/unicorn/) servers.

### Docker Compose, RubyMine, Rails 4 or greater

The `docker-compose.yml` file should look something like:

```yaml
command: bundle exec rails s -p 3000 -b 0.0.0.0

volumes: 
  - .:/sample_rails_app

extra_hosts:
  - "host.docker.internal:host-gateway" # Only required for Linux systems running Docker Desktop.

ports:
  - "3000:3000" # Rails port.
  - "1234:1234" # Port used for by ruby-debug-ide server.
  - "58430-58450:58430-58450" # Sub-process ports for multi-process servers (Unicorn, Passenger, etc).
```

Create a Docker Compose Remote Interpreter as outlined [here](https://www.jetbrains.com/help/ruby/using-docker-compose-as-a-remote-interpreter.html#configure_remote_interpreter).  Open up or create a Rails Run/Debug Configuration as outlined [here](https://www.jetbrains.com/help/ruby/run-rails-applications.html).  Make sure the Ruby SDK used is the Docker Compose one you setup .  

If you are using Docker Desktop make sure you set the Environment Variable to: `IDE_PROCESS_DISPATCHER=host.docker.internal:26162`.  If you don't set the `IDE_PROCESS_DISPATCHER` then ruby-debug-ide will try to respond to the address it receives requests from, which in the Docker world is usually 172.17.0.1.  See [here](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host) for more informaiton on Docker networking.   

On Linux you also need to make sure you set the `extra_hosts` as outlined above.

If you are using just plain old Docker on Linux then you don't need to set the `IDE_PROCESS_DISPATCHER` variable.

The port `26162` is the default port RubyMine uses when spawning the docker container.  For more details see the `docker-compose.override` file created by RubyMine when you click the green debug button.  

```shell
/usr/local/bin/docker-compose -f /home/localadmin/Repos/store/docker-compose.yml -f /home/localadmin/.cache/JetBrains/RubyMine2022.2/tmp/docker-compose.override.2581.yml up --exit-code-from web --abort-on-container-exit web
```

### Docker Compose, RubyMine, Rails 3 or less

Follow the steps in [Docker Compose, RubyMine, Rails 4 or greater](#docker-compose-rubymine-rails-4-or-greater).  The only change is you can't use the default Rails Run/Debug as support for Rails 3.2 was dropped in RubyMine version [2022.1](https://blog.jetbrains.com/ruby/2022/05/rubymine-to-retire-rails-3-and-other-outdated-features/).  Instead you need to create a [Gem Command](https://www.jetbrains.com/help/ruby/run-debug-configuration-gem-command.html) Run/Debug with the following settings:

- Gem name: rails
- Executable name: rails
- Arguments: s -p 3000 -h 0.0.0.0 # Other rails command line arguments as needed.
- Environment variables: IDE_PROCESS_DISPATCHER=host.docker.internal:26162 # If using Docker Desktop

The green RubyMine Run or Debug buttons should behalf as the used too when using the Rails Run/Debug configuration. 

### Command Line and Docker

Run the following command to start the debugging session for a Rails application:

```shell
rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 26162 -- bin/rails s
```

Feel free to add additional options to the rails command at the end such as port, horst, etc.

## ruby-debug-ide Bundled with RubyMine

By default the ruby-debug-ide gem is no longer published to [Rubygems](https://rubygems.org/gems/ruby-debug-ide) as outlined [here](https://github.com/ruby-debug/ruby-debug-ide/issues/201).  Instead it is included with RubyMine at `plugins/ruby/rb/gems`.  Two versions are included with RubyMine: 0.7.3 and 2.3.8.  The 2.3.8 gem, as of this writing, requires Ruby 2.3 or greater the run.

If you don't need to debug older Ruby applications or aren't using Docker you can probably just use the gems bundled with RubyMine.  To do so just list the gem in your Gemfile and RubyMine should do the rest.  For example:

```ruby
group :development, :test do
  gem "ruby-debug-ide"
  gem "debase"
end
```

## Contributing

If you have any questions, notice a bug, or have a suggestion/enhancement please let me know by opening [issue](https://github.com/corgibytes/ruby-debug-ide/issues) or [pull request](https://github.com/corgibytes/ruby-debug-ide/pulls).

### Development Environment Setup

The easiest way to get you development environment setup is to use [Docker](https://www.docker.com/).  [Install Docker](https://docs.docker.com/get-docker/) then run build the container:

```shell
docker-compose build
```

Then run the container:

```bash
docker-compose run --rm app bash
```

Note: The gems are not installed until the container is run and the [docker-entrypoint.sh](docker-entrypoint.sh) is called.

If you don't want to use Docker then you can install Ruby using [RVM](https://rvm.io/), [Rbenv](https://github.com/rbenv/rbenv), or any other method you like.

### Linting

Linting is done by [Standard](https://github.com/testdouble/standard).  To check that the code if formatted correctly run:

```shell
standardrb
```

When working on a file remove it from the [.standard_todo.yml](.standard_todo.yml) file and correct as many linting errors as you can.  Standard is [configured](.standard.yml) to lint the code base for Ruby 1.8 but sometimes it makes recommendations that would break on older Ruby versions.  If you spot a linting recommendation you should open an issue or pull request in [Standard](https://github.com/testdouble/standard). 

### Tests

Once you have your development environment setup make sure the tests all pass:

```bash
rake
```

## Acknowledgements

Thanks to [ruby-debug](https://github.com/ruby-debug) team [JetBrains](https://www.jetbrains.com/) for creating Ruby debugging gems.
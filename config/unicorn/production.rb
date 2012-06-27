# config/unicorn.rb
# Set environment to development unless something else is specified
env = ENV["RAILS_ENV"] || "development"

# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
worker_processes 4

listen 5000

# Preload our app for more speed
preload_app true

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

pid "/tmp/unicorn.pasteboard.me.pid"

# Production specific settings
# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
working_directory "~/public/pasteboard.me/pasteboard/current"

# feel free to point this anywhere accessible on the filesystem
user 'zevas'
shared_path = "~/public/pasteboard.me/pasteboard/shared"

#stderr_path "#{shared_path}/log/unicorn.stderr.log"
#stdout_path "#{shared_path}/log/unicorn.stdout.log"

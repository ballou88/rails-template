######################################################################
# Defualt rails template
#
#
######################################################################

# Set default variable values for setup
username = ENV['USER']
database_name = ask "What is the database base name? [default]"
database_name = "default" if database_name.blank?
database_username = ask "What is the database user name? [#{username}]"
database_username = username if database_username.blank?
database_password = ask "What is the database password? []"

# Comment out sqlite3
comment_lines 'Gemfile', /gem 'sqlite3'/

# Remove default database.yml and replace with values from user
remove_file('config/database.yml')
remove_file('public/index.html')
create_file('config/database.yml') do
  %Q{# PostgreSQL. Versions 8.2 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On Mac OS X with macports:
#   gem install pg -- --with-pg-config=/opt/local/lib/postgresql84/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem 'pg'
#
development:
  adapter: postgresql
  encoding: unicode
  database: #{database_name}_development
  pool: 5
  host: localhost
  username: #{database_username}
  password: #{database_password}

  # Connect on a TCP socket. Omitted by default since the client uses a
  # domain socket that doesn't need configuration. Windows does not have
  # domain sockets, so uncomment these lines.
  #host: localhost
  #port: 5432

  # Schema search path. The server defaults to $user,public
  #schema_search_path: myapp,sharedapp,public

  # Minimum log levels, in increasing order:
  #   debug5, debug4, debug3, debug2, debug1,
  #   log, notice, warning, error, fatal, and panic
  # The server defaults to notice.
  #min_messages: warning

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  adapter: postgresql
  encoding: unicode
  database: #{database_name}_test
  pool: 5
  host: localhost
  username: #{database_username}
  password: #{database_password}

production:
  adapter: postgresql
  encoding: unicode
  database: #{database_name}_production
  pool: 5
  host: localhost
  username: #{database_username}
  password: #{database_password}

  }
end
# Use Rspec/capybara/factory_girl and
# add some debugging tools
gem_group :development, :test do
  gem 'rspec-rails'
  gem 'pry'
  gem 'pry-remote'
  gem 'pry-stack_explorer'
  gem 'pry-debugger'
  gem 'growl'
  gem 'rb-fsevent', require: false
  gem 'factory_girl_rails'
  gem 'sextant'
  gem 'capybara'
  gem 'launchy'
  gem 'database_cleaner'
  gem 'faker'
  gem 'zeus'
  gem 'hpricot'
  gem 'ruby_parser'
end

gem_group :development do
  gem 'guard-rspec'
  gem 'guard-livereload'
  gem 'guard-rails'
  gem 'guard-annotate'
  gem 'rails-footnotes'
  gem "better_errors"
  gem "binding_of_caller"
end

gem_group :assets do
  gem 'bootstrap-sass'
end

gem 'thin'
gem 'haml'
gem 'haml-rails'
gem 'simple_form'
gem 'pg'

# Convert Application.html.erb to haml
run("for i in `find app/views/layouts -name '*.erb'` ; do html2haml -e $i ${i%erb}haml ; rm $i ; done")

# Initialize guard and set some defualts
run("bundle exec guard init")
insert_into_file "Guardfile", after: "guard 'rspec'" do
  ", all_after_pass: false, cli: '--color --format nested --fail-fast', all_on_start: false, keep_failed: false, notify: true"
end
insert_into_file "Guardfile", after: "guard 'rails'" do
  ", zeus: true, :server => :thin"
end

# Run Rspec install generator
generate("rspec:install")

# Create the database
rake 'db:create'

# Install devise if the user wants it and convert views to haml
if yes?("Would you like to install Devise?")
  # Install Devise
  gem 'devise'
  generate("devise:install")
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate("devise", model_name)
  generate("devise:views")
  run("for i in `find app/views/devise -name '*.erb'` ; do html2haml -e $i ${i%erb}haml ; rm $i ; done")
  create_file "spec/support/devise.rb" do
    %Q{
  RSpec.configure do |config|
    config.include Devise::TestHelpers, :type => :controller
  end
    }
  end
end

# Ask user if they would like simpleform, if so install bootstrap version
if yes?("Would you like to install SimpleForm?")
  generate("simple_form:install --bootstrap")
end

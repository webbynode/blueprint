require 'test_helper'

class BlueprintTest < Test::Unit::TestCase
  def rails_blueprint
    blueprint "Rails" do |f|
      f.provides "rails"

      f.parameter "version", :label => "Rails Version", :render_as => "combobox",
        :values => ["2.3.2", "2.2.2", "2.1.2"]

      f.parameter "doc_rdoc", :label => "Install rdoc", :render_as => "checkbox"
      f.parameter "doc_ri",   :label => "Install ri",   :render_as => "checkbox"

      f.parameter "create-dummyapp", 
        :label => "Create dummy app?", 
        :render_as => "checkbox",
        :attributes => {:default => "y"}
        
      f.parameter "dummyapp-path", 
        :label => "Path for dummy app",
        :render_as => "text",
        :attributes => {
          "required"         => "y",
          "default"          => "/var/rails",
          "validation"       => "^((?:\/[a-zA-Z0-9]+(?:_[a-zA-Z0-9]+)*(?:\-[a-zA-Z0-9]+)*)+)$",
          "validation_error" => "Use a valid path without an ending slash (ie, <code>/var/www</code>)"
        }

      f.parameter "dummyapp-database", 
        :label => "Database for dummy app", 
        :render_as => "combobox" do |p|

          p.value "sqlite3", :label => "SQLite 3"
          p.value "mysql", :label => "MySQL"
          p.value "sqlite2", :label => "SQLite 2"
          p.value "postgresql", :label => "PostgreSQL"

      end
    end
  end
  
  def rails_readystack_blueprint
    blueprint(:label => "Rails", :type => "readystack") do |f|
      # this blueprint delivers "rs.rails"
      f.provides "rs.rails"

      # dependencies and order of execution -- top => bottom
      # apache2/ngnix, mysql/postgre, passenger/mongrel
      f.requires :group => "webservers", 
                 :with => ["apache2", "nginx"]
      f.requires :group => "database",   
                 :with => ["mysql-server", "postgresqlserver"]
      f.requires "rails"
      f.requires :group => "proxy",      
                 :with => ["passenger", "mongrel_cluster"]

      # attributes
      f.attributes :required => 'y'
      f.outputs    :installed_gems => "^Installed following gems: (.*)",
                   :success_indicator => "^SUCCESS: (.*)"

      # always installs rails
      f.dependency "rails", :render_as => "hidden"

      # gives two webserver/proxy combo options:
      # apache2 + passenger or nginx + mongrel
      f.parameter "webserver-proxy", :label => "WebServer and Proxy" do |p|
        p.attributes :required => "y"

        p.aggregate "Apache2 and Passenger", :render_as => "radio" do |agr|
          agr.dependency "apache2"
          agr.dependency "passenger"
        end

        p.aggregate "Nginx and Mongrel Cluster", :render_as => "radio" do |agr|
          agr.dependency "nginx"
          agr.dependency "mongrel_cluster"
        end

        # doesn't install webserver/proxy
        p.aggregate "No webserver & proxy", :render_as => "radio" do |agr|
          agr.parameter "-"
        end
      end

      # database options: mysql or postgresql
      f.parameter "database-server", :label => "Database Server" do |p|
        p.attributes :required => "y"

        p.dependency "mysql-server",     :label => "MySQL",      :render_as => "radio"
        p.dependency "postgresqlserver", :label => "PostgreSQL", :render_as => "radio"
        p.no_op      "No database server", :render_as => "radio"
      end

      # list of gems
      f.aggregate "Additional Gems" do |agr|
        %w{will_paginate thoughtbot-paperclip 
          rspec authlogic hpricot capistrano}.each do |gem|

            agr.parameter "gem_#{gem}", :label => gem, :render_as => "checkbox"

        end
      end
    end
  end

  should "probably rename this file and start testing for real" do
    puts rails_blueprint.to_yaml
    puts rails_readystack_blueprint.to_yaml
  end
end

tracing = (Rake.application.options.trace)?"--trace":""
verbose = (Rake.application.options.verbose)?"--verbose":""

require 'rake'
require 'rubygems'

def sudo(cmd)
  puts "#{cmd}"
  %x[sudo -p "Password: " #{cmd}]
end

# recognized variables
vars = ['PKG_BUILD', 'RCOV_PARAMS', 'RAILS_ENV', 'RAILS_PARENT']
ENV['RAILS_PARENT'] = File.join(Dir.pwd, 'webservice')

env = ENV.map { |key,val| (ENV[key] && vars.include?( key )) ? %(#{key}="#{ENV[key]}") : nil }.reject {|x| x.nil?}.join(' ')

plugins = Dir.glob('plugins/*')#.reject{|x| ['users'].include?(File.basename(x))}
PROJECTS = ['webservice', *plugins]
desc 'Run all tests by default'
task :default => :test

%w(test rdoc pgem package release install install_policies check_syntax package-local buildrpm buildrpm-local test:test:rcov).each do |task_name|
  desc "Run #{task_name} task for all projects"

  task task_name do
    PROJECTS.each do |project|
      Dir.chdir(project) do
        system %(#{env} #{$0} #{tracing} #{task_name})
        raise "Error on execute '#{$0} #{tracing} #{verbose} #{task_name}' inside #{project}/" if $?.exitstatus != 0
      end
    end
  end

end

desc "Run doc to generate whole documentation"
task :doc do
  #clean old documentation
  puts "cleaning old doc"
  system "rm -rf doc"
  
  Dir.mkdir 'doc'
  copy 'index.html.template', "doc/index.html"
  #handle rest service separate from plugins
  puts "create framework documentation"
  Dir.chdir('webservice') do
    system "rake doc:app"
  end
    system "cp -r webservice/doc/app doc/webservice"
  puts "create plugins documentation"
  plugins_names = []
  Dir.chdir('plugins') do
    plugins_names = Dir.glob '*'
  end
  plugins_names.each do |plugin|
    Dir.chdir("plugins/#{plugin}") do
      system "rake doc:app"
    end
    system "cp -r plugins/#{plugin}/doc/app doc/#{plugin}"
  end
  puts "generate links for plugins"
  code = ""
  plugins_names.sort.each do |plugin|
    code = "#{code}<a href=\"./#{plugin}/index.html\"><b>#{plugin}</b></a><br>"
  end
  system "sed -i 's:%%PLUGINS%%:#{code}:' doc/index.html"
  puts "documentation successfully generated"
end

=begin
require 'metric_fu'
MetricFu::Configuration.run do |config|
        #define which metrics you want to use
        config.metrics  = [:churn, :saikuro, :flog, :reek, :roodi, :rcov] #missing flay and stats both not working
        config.graphs   = [:flog, :reek, :roodi, :rcov]
        config.flay     = { :dirs_to_flay => ['webservice', 'plugins']  } 
        config.flog     = { :dirs_to_flog => ['webservice', 'plugins']  }
        config.reek     = { :dirs_to_reek => ['webservice', 'plugins']  }
        config.roodi    = { :dirs_to_roodi => ['webservice', 'plugins'] }
        config.saikuro  = { :output_directory => 'tmp/metric_fu/output', 
                            :input_directory => ['webservice', 'plugins'],
                            :cyclo => "",
                            :filter_cyclo => "0",
                            :warn_cyclo => "5",
                            :error_cyclo => "7",
                            :formater => "html"} #this needs to be set to "text"
        config.churn    = { :start_date => "1 year ago", :minimum_churn_count => 10}
        config.rcov     = { :test_files => ['webservice/test/**/*_test.rb', 
                                            'plugins/**/test/**/*_test.rb'],
                            :rcov_opts => ["--sort coverage", 
                                           "--no-html", 
                                           "--text-coverage",
                                           "--no-color",
                                           "--profile",
                                           "--rails",
                                           "--exclude /gems/,/Library/,spec"]}
    end
=end

=begin
require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['webservice/app/**/*.rb','webservice/lib/**/*.rb','webservice/test/plugin_basic_tests.rb', 'plugins/*/app/**/*.rb', 'plugins/*/lib/**/*.rb','webservice/doc/README_FOR_APP', 'plugins/**/README_FOR_APP']   # optional
  t.options = ['--private', '--protected'] # optional
end
=end


# desc "Explaining what the task does"
# task :bullring do
#   # Task goes here
# end


desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r bullring.rb"
end
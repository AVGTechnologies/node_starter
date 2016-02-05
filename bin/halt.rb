
root = File.expand_path('../..', __FILE__)
path = File.join(root, '.pid')
if File.exist?(path)
  pid = File.read(path)
  Process.kill('TERM', pid.to_i)
else
  puts 'No pid file found'
end

def run_spec(file)
  unless File.exist?(file)
    puts "#{file} does not exist"
    return
  end

  puts "Running #{file}"
  system "bundle exec rspec #{file}"
  puts
end

watch("spec/.*/*_spec.rb") do |match|
  run_spec match[0]
end

watch("app/(.*/.*).rb") do |match|
  run_spec %{spec/#{match[1]}_spec.rb}
end

watch("app/(.*/.*).html.haml") do |match|
  run_spec %{spec/#{match[1]}_spec.rb}
end

watch("app/(.*/.*).html.erb") do |match|
  run_spec %{spec/#{match[1]}_spec.rb}
end

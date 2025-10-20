# Define the global platform for your project
platform :ios, '16.0'

target 'WeatherNow' do
  # Use dynamic frameworks
  use_frameworks!

  # Pods for WeatherNow
  pod 'SnapKit'
  pod 'Alamofire'

  target 'WeatherNowTests' do
    inherit! :search_paths
  end

  target 'WeatherNowUITests' do
    inherit! :search_paths
  end
end

# Post-install configuration to ensure compatibility
post_install do |installer|
  installer.pods_project.targets.each do |target|
    
    # Fix potential path resolution issues in generated shell scripts
    shell_script_path = "Pods/Target Support Files/#{target.name}/#{target.name}-frameworks.sh"
    if File.exist?(shell_script_path)
      shell_script_input_lines = File.readlines(shell_script_path)
      shell_script_output_lines = shell_script_input_lines.map do |line|
        line.sub("source=\"$(readlink \"${source}\")\"", "source=\"$(readlink -f \"${source}\")\"")
      end
      File.open(shell_script_path, 'w') { |f| f.puts(shell_script_output_lines) }
    end

    # Ensure build settings are correctly applied for all configurations
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'

      # Safely modify xcconfig if it exists
      if config.base_configuration_reference
        xcconfig_path = config.base_configuration_reference.real_path
        if File.exist?(xcconfig_path)
          xcconfig = File.read(xcconfig_path)
          xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
          File.open(xcconfig_path, "w") { |file| file.puts(xcconfig_mod) }
        end
      end
    end
  end
end
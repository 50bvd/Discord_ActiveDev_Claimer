# config_manager.rb
require 'dotenv'

def load_or_request_token
  # Load the .env file if it exists
  Dotenv.load if File.exist?('.env')
  
  # Check if the token exists and is valid
  token = ENV['DISCORD_TOKEN']
  
  if token.nil? || token.empty? || token == 'YOUR_TOKEN_HERE'
    puts "\n=== Discord Bot Configuration ==="
    puts "No valid Discord token found."
    puts "To get your token:"
    puts "1. Go to https://discord.com/developers/applications"
    puts "2. Create a new application or select an existing one"
    puts "3. Navigate to the 'Bot' tab"
    puts "4. Click 'Reset Token' or 'Copy' to retrieve your token\n\n"
    
    print "Please enter your Discord token: "
    token = gets.chomp
    
    # Create or update the .env file
    File.open('.env', 'w') do |f|
      f.puts "DISCORD_TOKEN=#{token}"
    end
    
    puts "\n✅ Token successfully saved in .env file!"
    puts "The bot will use this token for future launches.\n\n"
  end
  
  token
end
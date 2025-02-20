require 'discordrb'
require 'net/http'
require 'json'
require_relative 'ascii_art'
require_relative 'config_manager'

Signal.trap("INT") do
  puts "\n\n🛑 Graceful shutdown in progress..."
  bot.stop if defined?(bot)
  exit
end

# Display ASCII art
display_ascii_art

# Load token
token = load_or_request_token

begin
  # Initialize bot with required intents
  bot = Discordrb::Bot.new(
    token: token,
    intents: [:guilds, :server_members, :server_messages, :message_content]
  )

  puts "\n🚀 Bot is starting..."
  puts "🔗 Invite URL: #{bot.invite_url(permission_bits: 274_878_221_376)}\n\n"
  puts "🔧 Configuration Required:"
  puts "1. Go to https://discord.com/developers/applications"
  puts "2. Select your application"
  puts "3. Navigate to 'Bot' settings"
  puts "4. ENABLE PRIVILEGED INTENTS:"
  puts "   ✅ SERVER MEMBERS INTENT"
  puts "   ✅ MESSAGE CONTENT INTENT"
  puts "5. Click 'Save Changes'"
  puts "\nPress Enter to continue..."
  gets

  # Slash command for badge claim
  bot.register_application_command(:claimbadge, "Claim the Active Developer badge") do |cmd|
  end

  bot.application_command(:claimbadge) do |event|
    begin
      url = URI("https://discord.com/api/v10/applications/#{bot.profile.id}/role-connections/metadata")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      
      request = Net::HTTP::Put.new(url)
      request["Authorization"] = "Bot #{token}"
      request["Content-Type"] = "application/json"
      request.body = [{
        key: "active_developer",
        name: "Active Developer",
        description: "Active Developer Badge",
        type: 7
      }].to_json
      
      response = http.request(request)
      
      case response.code
      when "200", "201"
        event.respond(content: "✅ Badge request submitted! Check status in 24h:\nhttps://discord.com/developers/active-developer", ephemeral: true)
      when "401"
        event.respond(content: "❌ Authentication failed: Invalid bot token", ephemeral: true)
      when "429"
        event.respond(content: "⚠️ Rate limited. Try again later.", ephemeral: true)
      else
        event.respond(content: "❌ Unexpected error (HTTP #{response.code})", ephemeral: true)
      end
    rescue => e
      puts "⚠️ Command Error: #{e.message}"
      event.respond(content: "❌ Internal server error", ephemeral: true)
    end
  end

  # Handle disconnections
  bot.disconnected do
    puts "\n⚠️ Connection lost! Reconnecting..."
  end

  # Start bot
  bot.run(true)
  puts "\n🎉 Bot running successfully. Press Ctrl+C to exit."
  bot.sync

rescue Discordrb::Errors::InvalidAuthToken
  puts "\n❌ FATAL ERROR: Invalid bot token!"
  puts "Verify your .env file or visit:"
  puts "https://discord.com/developers/applications"
rescue => e
  puts "\n🔥 CRITICAL ERROR: #{e.message}"
  puts "Stack trace:"
  puts e.backtrace.first(3).join("\n")
end
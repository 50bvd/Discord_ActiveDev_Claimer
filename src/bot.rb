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

# Track bot startup time
START_TIME = Time.now

begin
  puts "\n🔄 Initializing bot..."
  
  # Initialize bot with minimal required intents
  bot = Discordrb::Bot.new(
    token: token,
    intents: [:guilds, :server_messages, :message_content]
  )

  puts "\n🚀 Bot is starting..."
  puts "🔗 Invite URL: #{bot.invite_url(permission_bits: 274_878_221_376)}\n\n"
  puts "🔧 Configuration Required:"
  puts "1. Go to https://discord.com/developers/applications"
  puts "2. Select your application"
  puts "3. Navigate to 'Bot' settings"
  puts "4. ENABLE PRIVILEGED INTENTS:"
  puts "   ✅ MESSAGE CONTENT INTENT"
  puts "5. Click 'Save Changes'"
  puts "\nPress Enter to continue..."
  gets

  # === BADGE CLAIM COMMAND ===
  bot.register_application_command(:claimbadge, "Claim the Active Developer badge") do |cmd|
  end

  bot.application_command(:claimbadge) do |event|
    begin
      puts "📝 Received /claimbadge command from user #{event.user.username} (#{event.user.id})"
      
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
      
      puts "🔄 Sending API request to Discord..."
      
      response = http.request(request)
      
      puts "✓ API Response: HTTP #{response.code}"
      puts "📄 Response Body: #{response.body.length > 100 ? response.body[0..100] + '...' : response.body}"
      
      case response.code
      when "200", "201"
        puts "✅ Badge request successful for user #{event.user.username}"
        event.respond(content: "✅ Badge request submitted! Check status in 24h:\nhttps://discord.com/developers/active-developer", ephemeral: true)
      when "401"
        puts "❌ Authentication failed: Invalid bot token"
        event.respond(content: "❌ Authentication failed: Invalid bot token", ephemeral: true)
      when "429"
        puts "⚠️ Rate limited. Try again later."
        event.respond(content: "⚠️ Rate limited. Try again later.", ephemeral: true)
      else
        puts "❌ Unexpected error (HTTP #{response.code}): #{response.body}"
        event.respond(content: "❌ Unexpected error (HTTP #{response.code})", ephemeral: true)
      end
    rescue => e
      puts "⚠️ Command Error: #{e.message}"
      puts e.backtrace.join("\n")
      event.respond(content: "❌ Internal server error", ephemeral: true)
    end
  end

  # === UPTIME COMMAND ===
  bot.register_application_command(:uptime, "Check how long the bot has been online") do |cmd|
  end
  
  bot.application_command(:uptime) do |event|
    uptime_seconds = (Time.now - START_TIME).to_i
    days = uptime_seconds / 86400
    hours = (uptime_seconds % 86400) / 3600
    minutes = (uptime_seconds % 3600) / 60
    seconds = uptime_seconds % 60
    
    uptime_text = "⏱️ **Bot Uptime**\n"
    uptime_text << "• **#{days}** days " if days > 0
    uptime_text << "• **#{hours}** hours " if hours > 0 || days > 0
    uptime_text << "• **#{minutes}** minutes " if minutes > 0 || hours > 0 || days > 0
    uptime_text << "• **#{seconds}** seconds"
    
    event.respond(content: uptime_text, ephemeral: true)
  end
  
  # === BOT INFO COMMAND ===
  bot.register_application_command(:botinfo, "Display information about the bot") do |cmd|
  end
  
  bot.application_command(:botinfo) do |event|
    server_count = bot.servers.size
    user_count = bot.users.size rescue 'Unknown'
    
    info = "🤖 **Bot Information**\n\n"
    info << "• **Name**: #{bot.profile.name}\n"
    info << "• **ID**: #{bot.profile.id}\n"
    info << "• **Servers**: #{server_count}\n"
    info << "• **Users**: #{user_count}\n"
    info << "• **Library**: Discordrb v#{Discordrb::VERSION}\n"
    info << "• **Ruby**: #{RUBY_VERSION}\n"
    info << "• **Developer**: <@125651939969990657>\n"
    info << "• **Uptime**: <#{Time.now - START_TIME} seconds>\n"
    
    event.respond(content: info, ephemeral: true)
  end
  
  # === HELP COMMAND ===
  bot.register_application_command(:help, "List available commands") do |cmd|
  end
  
  bot.application_command(:help) do |event|
    help_text = "📚 **Available Commands**\n\n"
    help_text << "• `/claimbadge` - Claim the Active Developer badge\n"
    help_text << "• `/uptime` - Check how long the bot has been online\n"
    help_text << "• `/botinfo` - Display information about the bot\n"
    help_text << "• `/help` - Show this help message\n"
    
    event.respond(content: help_text, ephemeral: true)
  end

  # Start bot
  puts "\n⏱️ Starting bot..."
  bot.run(true)
  puts "\n🎉 Bot running successfully. Press Ctrl+C to exit."
  puts "\n⚠️ Note: You may see cache warnings - they can be safely ignored as they don't affect functionality."
  bot.sync

  # Simple heartbeat to keep the bot alive
  loop do
    sleep 60
  end

rescue Discordrb::Errors::InvalidAuthToken
  puts "\n❌ FATAL ERROR: Invalid bot token!"
  puts "Verify your .env file or visit:"
  puts "https://discord.com/developers/applications"
rescue => e
  puts "\n🔥 CRITICAL ERROR: #{e.message}"
  puts "Stack trace:"
  puts e.backtrace.join("\n")
end

# With Dockerfile
__From root project directory__

```bash
docker build -f docker/Dockerfile -t discord-bot .
docker run -e DISCORD_TOKEN="INSERT_TOKEN_HERE" discord-bot
```

# With compose
__From root project directory__

*Syntax Linux/Unix*

```bash
DISCORD_TOKEN="INSERT_TOKEN_HERE" docker-compose -f docker/compose.yaml up --build
```

*Syntax Windows*

```powershell
# Set environment variable
$env:DISCORD_TOKEN = "INSERT_TOKEN_HERE"
docker-compose -f docker/compose.yml up --build
```
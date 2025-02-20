FROM ruby:3.2-alpine

WORKDIR /app

# Dépendances système + build
RUN apk add --no-cache --update build-base git

# Gestion des dépendances Ruby
COPY Gemfile docker/Gemfile.lock ./
RUN bundle install --jobs $(nproc) --retry 3

# Copie du code source
COPY src/ .

# Point d'entrée universel
CMD ["ruby", "bot.rb"]
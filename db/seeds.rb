# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'faker'
require 'request_faker'

Ahoy.geocode = false
ahoy = Ahoy::Tracker.new(request: RequestFaker.new)

logger = Logger.new($stdout)

def self.log_to_console(logger, msg, level = 0)
  logger.debug "#{'--' * level}> #{msg}"
end

# Delete all database rows
log_to_console logger, 'Starting to purge all database table'

ActiveRecord::Base.establish_connection
ActiveRecord::Base.connection.tables.each do |table|
  next if table == 'schema_migrations'

  ActiveRecord::Base.connection.execute("TRUNCATE #{table} RESTART IDENTITY CASCADE")
end

# Users
log_to_console logger, 'Starting to seed users'

user_arr = []

20.times do |n|
  log_to_console logger, "creating #{n}-th user", 1
  created_edited = Faker::Time.between(from: DateTime.new(2019, 1, 1), to: DateTime.now)
  temp_user = User.new(
    username: Faker::Alphanumeric.unique.alpha(number: 15),
    email: Faker::Internet.unique.email,
    verified: true
  )
  temp_user.password = '123456' # devise overwrites and assigns digest automatically
  temp_user.skip_confirmation!
  temp_user.save!

  ahoy.track 'User Created', {}, { time: created_edited }

  user_arr << temp_user
end

temp_user = User.new(
  username: 'admin',
  email: 'admin@cherp.chat',
  verified: true,
  admin: true
)
temp_user.password = '123456'
temp_user.skip_confirmation!
temp_user.save!

ahoy.track 'User Created'

user_arr << temp_user

# Tags
log_to_console logger, 'Starting to seed tags'

CardinalSettings::Tags.types.map do |tag_type_key, type_hash|
  type_hash['polarities'].each do |polarity|
    log_to_console logger, "creating tags for #{polarity}, #{tag_type_key}", 2
    created_edited = Faker::Time.between(from: DateTime.new(2019, 1, 1), to: DateTime.now)

    if type_hash['fill_in']
      # randomly generated fill_ins

      rand(1..5).times do
        created_edited = Faker::Time.between(from: DateTime.new(2019, 1, 1), to: DateTime.now)
        Tag.create!(
          name: Faker::Alphanumeric.alpha(number: 10).downcase,
          tag_type: tag_type_key,
          polarity: polarity
        )

        ahoy.track 'Tag Created', {}, { time: created_edited }
      end
    end

    # generate entries
    next unless type_hash.key?('entries')

    type_hash['entries'].each do |entry|
      Tag.create!(
        name: entry,
        tag_type: tag_type_key,
        polarity: polarity
      )
      ahoy.track 'Tag Created', {}, { time: created_edited }
    end
  end
end

# Prompts
log_to_console logger, 'Starting to seed prompts'

prompt_arr = []

user_arr.each do |e_user|
  log_to_console logger, "creating prompts for user #{e_user.id}", 2

  created_edited = Faker::Time.between(from: DateTime.new(2019, 1, 1), to: DateTime.new(2022, 10, 1))

  end_of_range = rand(2..15)
  (1..end_of_range).each do |_n|
    sentences = rand(1..15)
    selected_user = user_arr[rand(0..(user_arr.length - 1))]
    tags = Tag.limit(Random.rand(1..15)).order('RANDOM()')

    temp_p = Prompt.new(
      status: 'posted',
      starter: Faker::Lorem.unique.paragraphs(number: sentences).join("\n\n"),
      ooc: Faker::Lorem.unique.paragraphs(number: sentences).join("\n\n"),
      user: selected_user,
      tags: tags,
      created_at: created_edited,
      updated_at: created_edited
    )
    ahoy.track 'Prompt Created', { user_id: selected_user.id }, { time: created_edited }
    temp_p.save!
    # needed for ticket check
    temp_t = temp_p.tickets.first
    temp_t.created_at = temp_p.created_at
    temp_t.save!

    prompt_arr << temp_p
  end
end

# Filters
log_to_console logger, 'Starting to seed filters'

## Filters are too complicated to represent in programmatic generation,
## so they're better off being made manually

# Chats
user_arr.each do |user|
  log_to_console logger, "creating chats for user #{user.id}", 2

  # grab a random array of other users
  sample_array = user_arr.sample(rand(2..user_arr.length)) - [user]
  sample_array.each do |sample_user|
    random_prompt = Prompt.where(user:, status: 'posted').sample

    # create a chat with user and sample_user
    chat = random_prompt.answer(sample_user)
    chat.save!

    connect_code = ConnectCode.new(
      chat_id: chat.id,
      user: random_prompt.user,
      remaining_uses: random_prompt.default_slots - 2
    )
    ahoy.track 'ConnectCode Created', { user_id: random_prompt.user, chat_id: chat.id },
               { time: chat.prompt.created_at }
    ahoy.track 'ConnectCode Consumed', { user_id: random_prompt.user, chat_id: chat.id },
               { time: chat.prompt.created_at }
    ahoy.track 'ConnectCode Consumed', { user_id: sample_user.id, chat_id: chat.id }, { time: chat.prompt.created_at }
    connect_code.save!
    creation_message = "Chat created.  \n" \
                       "Connect code is: #{connect_code.code}. It has #{connect_code.remaining_uses} uses left."
    chat.messages << Message.new(content: creation_message)
  end
end

# Announcements
log_to_console logger, 'Starting to seed announcements'

100.times do |n|
  log_to_console logger, "creating #{n}-th announcement", 2

  created_edited = Faker::Time.between(from: DateTime.new(2019, 1, 1), to: DateTime.now)
  sentences = rand(1..15)
  Announcement.create!(
    title: Faker::Lorem.sentence,
    content: Faker::Lorem.paragraphs(number: sentences).join("\n\n"),
    created_at: created_edited,
    updated_at: created_edited
  )
end

50.times do
  Announcement.offset(rand(Announcement.count)).first.update(
    updated_at: Faker::Time.between(from: DateTime.now - 1.day, to: DateTime.now)
  )
end

AnalyticsJob.perform_now

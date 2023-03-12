# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'faker'

# Delete all database rows
Announcement.destroy_all

ChatUser.destroy_all
ConnectCode.destroy_all
Message.destroy_all
Chat.destroy_all

Filter.destroy_all
ObjectTag.destroy_all
Tag.destroy_all

Ticket.destroy_all
Prompt.destroy_all

User.destroy_all

# Users

user_arr = []

20.times do
  created_edited = Faker::Time.between(from: DateTime.new(2019, 1, 1), to: DateTime.now)
  temp_user = User.new(
    username: Faker::Alphanumeric.unique.alpha(number: 15),
    email: Faker::Internet.unique.email,
    verified: true
  )
  temp_user.password = '123456' # devise overwrites and assigns digest automatically
  temp_user.save!
  
  user_arr << temp_user
end

temp_user = User.new(
  username: 'admin',
  email: 'admin@cherp.chat',
  verified: true,
  admin: true
)
temp_user.password = '123456'
temp_user.save!

user_arr << temp_user

# Prompts

prompt_arr = []

user_arr.each do |e_user|
  created_edited = Faker::Time.between(from: DateTime.new(2019, 1, 1), to: DateTime.new(2022, 10, 1))

  end_of_range = rand(2..15)
  (1..end_of_range).each do |n|
    sentences = rand(1..15)
    temp_p = Prompt.create!(
      status: 'posted',
      starter: Faker::Lorem.unique.paragraphs(number: sentences).join("\n\n"),
      ooc: Faker::Lorem.unique.paragraphs(number: sentences).join("\n\n"),
      user: user_arr[rand(0..(user_arr.length - 1))],
      created_at: created_edited,
      updated_at: created_edited
    )
    # needed for ticket check
    temp_t = temp_p.tickets.first
    temp_t.created_at = temp_p.created_at
    temp_t.save!

    prompt_arr << temp_p
  end
end

# Tags

CardinalSettings::Tags.types.map do |tag_type_key, type_hash|
  type_hash['polarities'].each do |polarity|
    if type_hash['fill_in'] then
      # randomly generated fill_ins
      
      rand(1..5).times do 
        temp_tag = Tag.create!(
          name: Faker::Alphanumeric.alpha(number: 10).downcase,
          tag_type: tag_type_key,
          polarity: polarity
        )
    
        prompt_arr.each do |temp_prompt|
          if rand(0..1) == 0 then
            temp_prompt.tags << temp_tag
          end
        end
      end
    end

    # generate entries
    if type_hash.key?('entries') then
      type_hash['entries'].each do |entry| 
        temp_tag = Tag.create!(
          name: entry,
          tag_type: tag_type_key,
          polarity: polarity
        )
    
        prompt_arr.each do |temp_prompt|
          if rand(0..1) == 0 then
            temp_prompt.tags << temp_tag
          end
        end
      end
    end
  end
end

# Announcements

100.times do
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

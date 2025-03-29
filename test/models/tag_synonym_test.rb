# frozen_string_literal: true

require 'test_helper'

class TagSynonymTest < ActiveSupport::TestCase
  setup do
    @son_tag = tags(:son)
    @dad_tag = tags(:dad)
    @son_tag.parent = @dad_tag

    @capital = tags(:capital)
    # Array of (Tag::MAX_RECURSION_DEPTH + 2) Tags
    @generic_tags = []
    (0..(Tag::MAX_RECURSION_DEPTH + 1)).each do |n|
      temp = tags(:generic)

      # Generate a copy so as to not mutate original
      new_tag = Tag.new(
        name: "#{temp.name} with rank #{n}",
        tag_type: temp.tag_type,
        polarity: temp.polarity
      )
      new_tag.save

      # Add parent if we're not rank 0. Intentionally fails rubocop for anti-cycle testing purposes.
      # rubocop:disable Rails/SkipsModelValidations
      new_tag.update_column :synonym_id, @generic_tags[n - 1].id unless n.zero?
      # rubocop:enable Rails/SkipsModelValidations

      @generic_tags << new_tag
    end
  end

  test 'can get last in synonym chain' do
    test_synonym = @generic_tags[0]

    # Should be able to reach index 0 from this
    biggest_possible_away = Tag::MAX_RECURSION_DEPTH
    actual_synonym = Tag.chain_synonym(@generic_tags[biggest_possible_away], nil)

    assert_equal test_synonym, actual_synonym
  end

  test 'an update to a malformed synonym chain should fix them' do
    test_synonym = @generic_tags[0]

    test_tags = @generic_tags.drop(1).slice(0, 5) # drop test_synonym, then get five first tags
    test_tags.reverse!
    test_tags.each do |gen|
      gen.save
      assert_equal(
        test_synonym, gen.synonym,
        "|#{gen.name}|'s chain wasn't fixed and still points to |#{gen.synonym.name}| instead of |#{test_synonym.name}|"
      )
    end
  end

  test "can't get above #{Tag::MAX_RECURSION_DEPTH} depth in invalid synonym chain" do
    test_synonym = @generic_tags[0]

    # Shouldn't be able to reach tag at index 0 from this
    not_possible_away = Tag::MAX_RECURSION_DEPTH + 1
    actual_synonym = Tag.chain_synonym(@generic_tags[not_possible_away], nil)

    assert_not_equal test_synonym, actual_synonym
  end

  test 'can get duplicates from real tag' do
    real_tag = Tag.create(
      name: 'real',
      tag_type: 'detail',
      polarity: 'misc'
    )

    duplicates = []
    (1..2).each do |n|
      temp_dupe = Tag.create(
        name: "#{real_tag.name} dupe ##{n}",
        tag_type: 'detail',
        polarity: 'misc',
        synonym: real_tag
      )

      duplicates << temp_dupe
    end

    db_duplicates = real_tag.duplicates.order(:id).to_a
    assert_equal duplicates.length, db_duplicates.length

    # checks that arrays have same contents
    (0..(duplicates.length - 1)).each do |n|
      assert_operator duplicates[n], :identical?, db_duplicates[n]
    end
  end
end

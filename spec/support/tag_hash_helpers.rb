# typed: false

module TagHashHelpers
  # find or create a tag where (id % 64) == remainder
  def find_or_create_tag_with_remainder(remainder)
    tag = Tag.find { |t| (t.id % 64) == remainder }
    return tag if tag

    max_id = Tag.maximum(:id) || 0
    target_id = ((max_id / 64) + 1) * 64 + remainder
    needed = target_id - max_id + 5

    needed.times do
      t = create(:tag)
      return t if (t.id % 64) == remainder
    end

    nil
  end
end

RSpec.configure do |config|
  config.include TagHashHelpers, type: :model
end

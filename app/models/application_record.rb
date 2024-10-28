# typed: false

require "vips"

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # https://stackoverflow.com/questions/50026344/composing-activerecord-scopes-with-selects
  scope :select_fix, -> { select(arel_table.project(Arel.star)) }

  # TODO https://github.com/rails/rails/pull/49231/files
  def self.has_one_attached_image(*args, &)
    name = args.first

    has_one_attached(*args, &)

    # for preloading
    define_singleton_method :"#{name}_includes" do
      {
        avatar_attachment: [blob: {variant_records: [:blob, :image_attachment, :image_blob]}],
        avatar_blob: {variant_records: :blob}
      }
    end

    validate :"validate_#{name}_is_image"

    define_method :"validate_#{name}_is_image" do
      return true unless avatar.attached?

      # Overwrite the user's filename for the avatar to avoid leaking it. ActiveStorage duplicates
      # this filename down to the variants. It would be nice to name them username_variant.ext, but
      # it doesn't seem possible to reflect on those ActiveStorage::Blob objects.
      avatar.filename = "#{username}.#{avatar.filename.extension}"

      begin
        # vips throws if the image metadata is invalid
        attachment = attachment_changes["avatar"].attachable.tempfile.read
        image = Vips::Image.new_from_buffer attachment, "revalidate=true"

        loader = image.get("vips-loader")
        raise Vips::Error unless loader.start_with?("jpegload", "pngload")

        # force vips to process the entire image, which might also cause it to throw on invalid data
        image.avg
        true
      rescue Vips::Error
        errors.add(:avatar, "is not a valid jpeg or png")
        avatar.purge
        false
      end
    end
  end
end

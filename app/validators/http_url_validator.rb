class HttpUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.present?

    begin
      uri = URI.parse(URI.encode(value))
      return if uri.is_a?(URI::HTTP) && !uri.host.nil? && uri.host.include?('.')
      raise URI::InvalidURIError
    rescue URI::InvalidURIError
      record.errors.add(attribute, 'is not a valid HTTP URL')
    end
  end
end

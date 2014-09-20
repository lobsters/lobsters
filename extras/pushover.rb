class Pushover

  def self.sounds
    Pushover.sounds
  end

  def self.push(user, device, params)
    if !@@API_KEY
      return
    end

    message_to_send = params[:message][0,511] || "No message"

    Pushover.notification(message: message_to_send, user: user, device: device)
  end
end

class MessageProcessor

  def initialize
    @slack_web_client = Slack::Web::Client.new
  end

  def collectUserInfo(data:)
    user = User.where(slack_user_id: data.user).first
    if user.blank?
      user_info = @slack_web_client.users_info(user: data.user)

      user = User.new
      user.slack_user_id = user_info['user']['id']
      user.name = user_info['user']['name']
      user.real_name = user_info['user']['real_name']
      user.tz = user_info['user']['tz']
      user.tz_offset = user_info['user']['tz_offset']
      user.contacts = user_info['user']['profile']['email']
      user.save
    end
  end

  def save_message_for_reminder(data:)
    message = Message.new
    message.message_id = data.client_msg_id
    message.ts = data.ts
    message.thread_ts = data.thread_ts
    message.event_ts = data.event_ts
    message.channel_id = data.channel
    message.remind_needed = true
    message.save
  end

  def disable_message_from_remind(data:)
    message = Message.where(ts: data.thread_ts).first
    message.remind_needed = false
    message.save
  end
end
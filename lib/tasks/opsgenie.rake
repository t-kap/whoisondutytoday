import 'bot/commands.rb'
import 'bot/notify.rb'

namespace :opsgenie do
  task :rotate => :environment do
    opsgenie_schedules = Duty.where.not(opsgenie_schedule_name: nil).or(Duty.where(opsgenie_schedule_name: "")).map(&:opsgenie_schedule_name).uniq
    notification = NotifyOpsgenie.new

    opsgenie_schedules.each do |shedule_name|
      json_response = JSON.parse(notification.GetOnCall(schedule_name: shedule_name).body)
      user = User.where('lower(contacts) = ?', json_response['data']['onCallRecipients'][0].downcase).first
      duty = Duty.where(user_id: user.slack_user_id, enabled: true).first
      begin
        if duty.user_id == user.slack_user_id
          p "Schedule for user already active:#{duty.user.name}"
        else
          p "Rotate schedule for user: #{duty.user.name}"
          Duty.where(channel_id: data.channel).where(user_id: user.slack_user_id).update_all(enabled: true)
          Duty.where(channel_id: data.channel).where.not(user_id: user.slack_user_id).update_all(enabled: false)
        end
      rescue StandardError => e
        Duty.where(channel_id: data.channel).where(user_id: user.slack_user_id).update_all(enabled: true)
        Duty.where(channel_id: data.channel).where.not(user_id: user.slack_user_id).update_all(enabled: false)
      end
    end
  end
end
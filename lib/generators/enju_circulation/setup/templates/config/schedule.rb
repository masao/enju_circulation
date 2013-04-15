
every 5.minute do
  rake "enju:message:send"
end

every 1.day, :at => '0:00 am' do
  rake "enju:circulation:expire"
  runner "User.lock_expired_users"
end

every 1.day, :at => '1:00 am' do
  rake "enju:circulation:stat"
#  rake "enju:bookmark:stat"
end

every 1.day, :at => '5:00 am' do
  rake "enju:circulation:send_notification"
  rake "enju:import:destroy"
end

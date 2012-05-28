class UserReserveStat < ActiveRecord::Base
  attr_accessible :start_date, :end_date, :note
  include CalculateStat
  default_scope :order => 'user_reserve_stats.id DESC'
  scope :not_calculated, where(:state => 'pending')
  has_many :reserve_stat_has_users
  has_many :users, :through => :reserve_stat_has_users

  state_machine :initial => :pending do
    before_transition :pending => :completed, :do => :calculate_count
    event :calculate do
      transition :pending => :completed
    end
  end

  def self.per_page
    10
  end

  def calculate_count
    self.started_at = Time.zone.now
    User.find_each do |user|
      daily_count = user.reserves.created(self.start_date, self.end_date).size
      if daily_count > 0
        self.users << user
        sql = ['UPDATE reserve_stat_has_users SET reserves_count = ? WHERE user_reserve_stat_id = ? AND user_id = ?', daily_count, self.id, user.id]
        ActiveRecord::Base.connection.execute(
          self.class.send(:sanitize_sql_array, sql)
        )
      end
    end
    self.completed_at = Time.zone.now
  end
end
# == Schema Information
#
# Table name: user_reserve_stats
#
#  id           :integer         not null, primary key
#  start_date   :datetime
#  end_date     :datetime
#  note         :text
#  state        :string(255)
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  started_at   :datetime
#  completed_at :datetime
#


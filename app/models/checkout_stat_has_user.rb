class CheckoutStatHasUser < ActiveRecord::Base
  attr_accessible
  attr_accessible :user_checkout_stat_id, :user_id,
    :as => :admin
  belongs_to :user_checkout_stat
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :user_checkout_stat_id
  validates_presence_of :user_checkout_stat_id, :user_id

  def self.per_page
    10
  end
end

# == Schema Information
#
# Table name: checkout_stat_has_users
#
#  id                    :integer         not null, primary key
#  user_checkout_stat_id :integer         not null
#  user_id               :integer         not null
#  checkouts_count       :integer         default(0), not null
#  created_at            :datetime
#  updated_at            :datetime
#


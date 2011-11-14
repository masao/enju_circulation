module EnjuCirculation
  module Manifestation
    def next_reservation
      self.reserves.waiting.order('reserves.created_at ASC').first
    end

    def available_checkout_types(user)
      if user
        user.user_group.user_group_has_checkout_types.available_for_carrier_type(self.carrier_type)
      end
    end

    def is_reservable_by?(user)
      return false if items.for_checkout.empty?
      unless user.has_role?('Librarian')
        unless items.size == (items.size - user.checkouts.overdue(Time.zone.now).collect(&:item).size)
          return false
        end
      end
      true
    end

    def is_reserved_by?(user)
      return nil unless user
      reserve = Reserve.waiting.where(:user_id => user.id, :manifestation_id => id).first
      if reserve
        reserve
      else
        false
      end
    end

    def is_reserved?
      if self.reserves.present?
        true
      else
        false
      end
    end

    def checkouts(start_date, end_date)
      Checkout.completed(start_date, end_date).where(:item_id => self.items.collect(&:id))
    end

    def checkout_period(user)
      if available_checkout_types(user)
        available_checkout_types(user).collect(&:checkout_period).max || 0
      end
    end

    def reservation_expired_period(user)
      if available_checkout_types(user)
        available_checkout_types(user).collect(&:reservation_expired_period).max || 0
      end
    end
  end
end

class Manifestation < ActiveRecord::Base
  include EnjuCirculation::Manifestation

  has_many :reserves, :foreign_key => :manifestation_id
end
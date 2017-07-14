class User < ApplicationRecord
  
  # Before
  # scope :recently_updated, where("updated_at <= #{Date.today - 2.days}")
  
  # After
  # - Scope body needs to be callable
  # - Use a parameter instead of string interpolation
  # - Use Time.now instead of Date.today
  scope :recently_updated, -> { where("updated_at >= ?", Time.now - 2.days) }

end

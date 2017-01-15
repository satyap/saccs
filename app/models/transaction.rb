class Transaction < ActiveRecord::Base
  belongs_to :account

  scope :cleared, ->{ where(cleared: true) }

  def toggle_clear!
    self.cleared = !self.cleared
    self.save
  end

  def date
    sprintf("%s-%02d", month, date_day)
  end

  def month
    sprintf("%04d-%02d", date_year, date_month)
  end
end

class Account < ActiveRecord::Base
  has_many :transactions

  scope :archived, ->{ where(archived: true) }
  scope :active, ->{ where.not(archived: true) }

  def transactions_by_month(yearmonth)
    year, month = yearmonth.split('-')
    return transactions.
      where(date_year: year, date_month: month).
      order('date_day desc, id desc')
  end

  def months
    transactions.
      select('date_year, date_month').
      order('date_year desc, date_month desc').
      uniq.
      group_by &:date_year
  end

  def month(date=nil)
    (date || Date.today).strftime("%Y-%m")
  end
end

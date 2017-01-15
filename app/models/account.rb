class Account < ActiveRecord::Base
  has_many :transactions

  scope :archived, -> { where(archived: true) }
  scope :active, -> { where.not(archived: true) }

  class Month
    attr_reader :year, :month

    def initialize(yearmonth)
      @year, @month = yearmonth.split('-')
    end
  end

  def beginning_balance(yearmonth, cleared_only=false)
    month = Month.new(yearmonth)
    trans = transactions.
      where("date_year < :year OR (date_year = :year and date_month < :month)",
        {
          year: month.year,
          month: month.month
        })
    trans = trans.where(cleared: true) if cleared_only
    return trans.sum(:amount)
  end

  def transactions_by_month(yearmonth)
    month = Month.new(yearmonth)
    return transactions.
      where(date_year: month.year, date_month: month.month).
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

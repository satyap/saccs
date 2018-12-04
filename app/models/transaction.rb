class Transaction < ActiveRecord::Base
  belongs_to :account

  scope :in_order, -> { order('date_year desc, date_month desc, date_day desc')}
  scope :cleared, -> { where(cleared: true) }

  def toggle_clear!
    self.cleared = !self.cleared
    self.save!
    self.account_month.update_amounts!
  end

  def date
    sprintf("%s-%02d", month, date_day)
  end

  def month
    sprintf("%04d-%02d", date_year, date_month)
  end

  def account_month
    account.months.where(year: date_year, month: date_month).first
  end

  def self.oldmig
    connection.execute(<<-SQL)
    insert into transactions (id, account_id,
    date_year,
    date_month,
    date_day,
    description,
    amount,
    cleared
    )
    select id, account,
strftime("%Y", ondate),
strftime("%m", ondate),
strftime("%d", ondate),
 descr,amt,case cleared
    when 'y' then 't'
    when '1' then 't'
    else 'f'
    end
from details
    SQL
  end
end

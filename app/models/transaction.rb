class Transaction < ActiveRecord::Base
  belongs_to :account

  scope :cleared, -> { where(cleared: true) }

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

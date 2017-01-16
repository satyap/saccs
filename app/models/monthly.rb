class Monthly < ActiveRecord::Base
  belongs_to :account

  def month
    name.split('-').last
  end

  def year
    name.split('-').first
  end

  def transactions
    account.
      transactions.
      where(date_year: year).
      where(date_month: month).
      order('date_day desc, id desc')
  end

  def balance
    transactions.sum(:amount) || 0
  end

  def cleared_balance
    transactions.cleared.sum(:amount) || 0
  end

  def update_amounts!
    update!(end_amount: start_amount + balance)
  end

  def self.oldmig
    connection.execute(<<-SQL)
      insert into monthlies (id,account_id, start_amount, end_amount, name)
      select id,account, startamt, endamt,
      strftime("%Y-%m", startdate)
      from monthly;
    SQL
  end
end

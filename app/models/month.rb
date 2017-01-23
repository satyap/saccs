class Month < ActiveRecord::Base
  belongs_to :account

  scope :in_order, -> { order('year desc, month desc')}

  def name
    sprintf("%04d-%02d", year, month)
  end

  def transactions
    account.
      transactions.
      where(date_year: year).
      where(date_month: month).
      order('date_day desc, id desc')
  end

  def spending
    transactions.sum(:amount) || 0
  end

  def cleared_spending
    transactions.cleared.sum(:amount) || 0
  end

  def update_amounts!
    update!(end_amount: start_amount - spending)
  end

  def self.oldmig
    connection.execute(<<-SQL)
      insert into monthly (id,account_id, start_amount, end_amount, `year`, `month`)
      select id,account, startamt, endamt,
      strftime("%Y", startdate),
      strftime("%m", startdate)
      from monthly;
    SQL
  end
end

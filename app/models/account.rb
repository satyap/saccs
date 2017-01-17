class Account < ActiveRecord::Base
  has_many :transactions
  has_many :months

  scope :archived, -> { where(archived: true) }
  scope :active, -> { where.not(archived: true) }

  def latest_month
    months.in_order.first
  end

  def self.oldmig
    connection.execute("insert into accounts (id,name) select id,name from acold")
  end
end

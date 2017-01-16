class Account < ActiveRecord::Base
  has_many :transactions
  has_many :monthlies

  scope :archived, -> { where(archived: true) }
  scope :active, -> { where.not(archived: true) }

  def latest_month
    monthlies.order('name desc').first
  end

  def self.oldmig
    connection.execute("insert into accounts (id,name) select id,name from acold")
  end
end

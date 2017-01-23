require 'rails_helper'

describe TransactionsController do
  render_views

  describe 'clearing transactions' do
    let(:year) { 2012 }
    let(:date_month) { 9 }
    let!(:account) { FactoryGirl.create(:account) }
    let!(:month) { FactoryGirl.create(:month, start_amount: 256, year: year, month: date_month, account: account) }
    let!(:transaction) { FactoryGirl.create(:transaction, amount: 1, date_year: year, date_month: date_month, account: account) }
    let!(:transaction_2) { FactoryGirl.create(:transaction, amount: 2, date_year: year, date_month: date_month, account: account) }

    let(:td) { "<\\/td>\\n<td>" }

    it 'marks transaction as cleared' do
      expect {
        xhr :post, :clear, id: transaction.id
      }.to change { transaction.reload.cleared? }.from(false).to(true)

      expect(response.body).to include "Balance:#{td}$253.00"
      expect(response.body).to include "Cleared balance:#{td}$255.00"
      expect(response.body).to include "Beginning balance:#{td}$256.00"
      expect(response.body).to include "Ending balance:#{td}$253.00"
    end

    it 'marks transaction as not cleared' do
      transaction.update!(cleared: true)

      expect {
        xhr :post, :clear, id: account.id
      }.to change { transaction.reload.cleared? }.from(true).to(false)

      expect(response.body).to include "Balance:#{td}$253.00"
      expect(response.body).to include "Cleared balance:#{td}$256.00"
      expect(response.body).to include "Beginning balance:#{td}$256.00"
      expect(response.body).to include "Ending balance:#{td}$253.00"
    end
  end

end

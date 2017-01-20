require 'rails_helper'

describe MonthsController do
  render_views
  let(:account) { FactoryGirl.create(:account) }

  describe 'create month' do
    it 'creates a new month' do
      expect {
        post :create, month: {year: '2013', account_id: account.id, month: '12', start_amount: 2000}
      }.to change { account.months.count }.from(0).to(1)
      month = account.months.last

      expect(response).to redirect_to(account_path(id: account, month_id: month.id))

      expect(month.year).to eq 2013
      expect(month.month).to eq 12
      expect(month.start_amount).to eq 2000
    end
  end
end
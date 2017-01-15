require 'rails_helper'

describe AccountsController do

  describe '/show' do
    describe 'balances' do
      render_views

      let(:month) { 10 }
      let(:year) { 2016 }
      let(:yearmonth) { "#{year}-#{month}" }
      let(:account) { FactoryGirl.create(:account) }
      let!(:this_month_transaction) {
        FactoryGirl.create(:transaction,
          account: account, amount: 1,
          date_year: year, date_month: month, date_day: 1
        )
      }
      let!(:past_month_transaction) {
        FactoryGirl.create(:transaction,
          account: account, amount: 10.90,
          date_year: year, date_month: month-1, date_day: 1
        )
      }
      let!(:past_month_cleared_transaction) {
        FactoryGirl.create(:transaction,
          account: account, amount: 11.70,
          cleared: true,
          date_year: year, date_month: month-1, date_day: 1
        )
      }
      let!(:future_transaction) {
        FactoryGirl.create(:transaction,
          account: account, amount: 0.25,
          cleared: true,
          date_year: year, date_month: month+1, date_day: 1
        )
      }

      before { get :show, id: account.id, month: yearmonth }

      it 'includes the balance' do
        expect(response.body).to include "\nBalance:\n$23.60"
      end

      it 'includes the cleared balance' do
        expect(response.body).to include "Cleared balance:\n$11.70"
      end
    end
  end

end
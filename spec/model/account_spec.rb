require 'rails_helper'

describe Account do

  describe '#beginning_balance' do
    subject { account.beginning_balance("#{year}-#{month}") }
    let(:month) { 10 }
    let(:year) { 2016 }
    let(:account) { FactoryGirl.create(:account) }
    let!(:same_month_transaction) {
      FactoryGirl.create(:transaction,
        account: account, amount: 1,
        date_year: year, date_month: month
      )
    }
    let!(:future_transaction) {
      FactoryGirl.create(:transaction,
        account: account, amount: 0.25,
        date_year: year, date_month: month+1
      )
    }
    let!(:different_account_transaction) {
      FactoryGirl.create(:transaction,
        amount: 0.5,
        date_year: year-1, date_month: month-1
      )
    }

    context 'no transactions' do
      it { is_expected.to eq 0 }
    end

    context 'transactions in same year' do
      let!(:transactions) {
        [
          FactoryGirl.create(:transaction,
            account: account, amount: 2,
            date_year: year, date_month: 2
          ),
          FactoryGirl.create(:transaction,
            account: account, amount: 4,
            date_year: year, date_month: 1
          ),
        ]
      }
      it { is_expected.to eq 6 }
    end

    context 'transactions in previous year' do
      let!(:transactions) {
        [
          FactoryGirl.create(:transaction,
            account: account, amount: 8,
            date_year: year-1, date_month: 2
          ),
          FactoryGirl.create(:transaction,
            account: account, amount: 16,
            date_year: year, date_month: 1
          ),
        ]
      }
      it { is_expected.to eq 24 }
    end

    context 'cleared transactions' do
      subject { account.beginning_balance("#{year}-#{month}", true) }
      let!(:transactions) {
        [
          FactoryGirl.create(:transaction,
            account: account, amount: 8,
            date_year: year-1, date_month: 2
          ),
          FactoryGirl.create(:transaction,
            account: account, amount: 16,
            cleared: true,
            date_year: year, date_month: 1
          ),
        ]
      }
      it { is_expected.to eq 16 }
    end
  end
end
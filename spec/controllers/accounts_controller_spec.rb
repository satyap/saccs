require 'rails_helper'

describe AccountsController do
  render_views

  describe 'create account' do
    it 'creates a new account' do
      expect {
        post :create, account: {name: "first bank"}
      }.to change { Account.count }.from(0).to(1)
    end

    context 'creates a first month' do
      before do
        Timecop.freeze('2015-02-24') do
          post :create, account: {name: "first bank"}
          expect(response).to redirect_to(account_path(Account.last.id))
        end
      end

      it 'sets the start amount to 0' do
        expect(Account.last.latest_month.start_amount).to eq 0
      end
    end
  end

  describe 'show account' do
    before do
      Timecop.freeze('2015-02-24') do
        post :create, account: {name: "first bank"}
        expect(response).to redirect_to(account_path(Account.last.id))
      end
      FactoryGirl.create(:transaction,
        date_month: 2,
        date_year: 2015,
        account: Account.last,
        amount: 209, description: 'formula 209.1'
      )
      FactoryGirl.create(:transaction,
        date_month: 3,
        date_year: 2015,
        account: Account.last,
        amount: 211, description: 'formula 211.2'
      )
    end

    it 'shows the current month' do
      get :show, id: Account.last.id
      expect(response.body).to include "first bank\n2015-02"
    end

    it 'sets the end amount to the balance' do
      latest_month = Account.last.latest_month
      latest_month.update!(start_amount: 200)

      get :show, id: Account.last.id, month_id: latest_month
      latest_month.reload
      expect(latest_month.end_amount).to eq 409
    end

    it 'shows the correct transactions' do
      get :show, id: Account.last.id
      expect(response.body).to include 'formula 209.1'
      expect(response.body).not_to include 'formula 211.2'
    end

  end

  describe 'archiving accounts' do
    let(:account) { FactoryGirl.create(:account) }

    it 'archives accounts' do
      expect {
        post :toggle_archive, id: account.id
      }.to change{ account.reload.archived?}.from(false).to(true)

      expect(response).to redirect_to(account_path(account.id))
    end

    it 'unarchives accounts' do
      account.update(archived: true)

      expect {
        post :toggle_archive, id: account.id
      }.to change{ account.reload.archived?}.from(true).to(false)

      expect(response).to redirect_to(account_path(account.id))
    end
  end
end

class AccountsController < ApplicationController
  def index
    @account = Account.new
  end

  def create
    Account.create(name: params[:account][:name])
    redirect_to accounts_path
  end

  def show
    @account = Account.find(params[:id])
    if params[:month]
      session[:month] = params[:month]
    else
      session[:month] ||= @account.month
    end
    @transaction = Transaction.new(
      account_id: @account.id,
      date_year: Date.today.year,
      date_month: Date.today.month,
      date_day: Date.today.day,
      amount: 0.0,
    )
    @transactions = @account.transactions_by_month(session[:month])
  end
end

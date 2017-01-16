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
    if params[:month_id]
      session[:month_id] = params[:month_id]
    else
      unless session[:month_id] and @account.monthly_ids.include?(session[:month_id])
        @month = @account.latest_month
        session[:month_id] = @month.id
      end
    end
    @month ||= Monthly.find(session[:month_id])
    @transaction = Transaction.new(
      account_id: @account.id,
      date_year: @month.year,
      date_month: @month.month,
      date_day: Date.today.day,
      amount: 0.0,
    )
  end
end

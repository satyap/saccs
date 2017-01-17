class AccountsController < ApplicationController
  def index
    @account = Account.new
  end

  def create
    ac = Account.create!(name: params[:account][:name])
    today = Date.today
    Month.create!(account: ac, year: today.year, month: today.month, start_amount: 0)
    redirect_to account_path(ac.id)
  end

  def show
    @account = Account.find(params[:id])
    if params[:month_id]
      session[:month_id] = params[:month_id]
    else
      unless session[:month_id] and @account.month_ids.include?(session[:month_id])
        @month = @account.latest_month
        session[:month_id] = @month.id
      end
    end
    @month ||= Month.find(session[:month_id])
    @transaction = Transaction.new(
      account_id: @account.id,
      date_year: @month.year,
      date_month: @month.month,
      date_day: Date.today.day,
      amount: 0.0,
    )
    @month.update_amounts!
  end
end

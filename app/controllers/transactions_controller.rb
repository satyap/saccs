class TransactionsController < ApplicationController

  def create
    transaction = Transaction.create(safe_params)
    redirect_to account_path(id: transaction.account_id)
  end

  def edit
    @transaction = Transaction.find(params[:id])
  end

  def update
    @transaction = Transaction.find(params[:id])
    @transaction.update(safe_params)
    Month.find(session[:month_id]).update_amounts!
    redirect_to account_path(id: @transaction.account_id)
  end

  def clear
    @transaction = Transaction.find(params[:id])
    @transaction.toggle_clear!
    @month = Month.find(session[:month_id])
    @month.update_amounts!
    respond_to do |format|
      format.js
    end
  end

  def destroy
    redirect_to account_path(id: Transaction.where(params[:id]).pluck(:account_id).first)
    Transaction.destroy(params[:id])
  end

  private

  def safe_params
    params.require(:transaction).permit(
      :account_id,
      :description,
      :date_year,
      :date_month,
      :date_day,
      :amount
    )
  end
end

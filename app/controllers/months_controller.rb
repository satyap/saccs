class MonthsController < ApplicationController
  def create
    month = Month.create!(safe_params)
    redirect_to account_path(id: month.account_id, month_id: month.id)
  end

  def edit
    @month = Month.find(params[:id])
  end

  def update
    month = Month.find(params[:id])
    month.update(safe_params)
    redirect_to account_path(id: month.account_id, month_id: month.id)
  end

  def destroy
    month = Month.find(params[:id])
    redirect_to account_path(id: month.account_id)
    month.destroy
  end

  private

  def safe_params
    params.require(:month).permit(
      :start_amount,
      :year,
      :month,
      :end_amount,
      :account_id # not actually secure! should be set from session or something
    )
  end
end
class TransfersController < ApplicationController
  layout :with_sidebar

  before_action :set_transfer, only: %i[destroy show update]

  def new
    @transfer = Transfer.new
  end

  def show
  end

  def create
    from_account = Current.family.accounts.find(transfer_params[:from_account_id])
    to_account = Current.family.accounts.find(transfer_params[:to_account_id])

    @transfer = Transfer.from_accounts(
      from_account: from_account,
      to_account: to_account,
      date: transfer_params[:date],
      amount: transfer_params[:amount].to_d
    )

    if @transfer.save
      @transfer.sync_account_later

      flash[:notice] = t(".success")

      respond_to do |format|
        format.html { redirect_back_or_to transactions_path }
        redirect_target_url = request.referer || transactions_path
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, redirect_target_url) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @transfer.update_entries!(transfer_update_params)
    redirect_back_or_to transactions_url, notice: t(".success")
  end

  def destroy
    @transfer.destroy!
    redirect_back_or_to transactions_url, notice: t(".success")
  end

  private
    def set_transfer
      @transfer = Transfer.find(params[:id])

      raise ActiveRecord::RecordNotFound unless @transfer.belongs_to_family?(Current.family)
    end

    def transfer_params
      params.require(:transfer).permit(:from_account_id, :to_account_id, :amount, :date, :name, :excluded)
    end

    def transfer_update_params
      params.require(:transfer).permit(:excluded, :notes)
    end
end

class Admin::CurrenciesController < AdminController
  def index
    @currencies = Currency.all
  end

  def new
    @currency = Currency.new
  end

  def create
    @currency = Currency.new(currency_params)
    if @currency.save
      redirect_to admin_currencies_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
  def currency_params
    params.require(:name)
  end
end

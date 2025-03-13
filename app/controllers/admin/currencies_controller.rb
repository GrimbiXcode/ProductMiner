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

  def edit
    @currency = Currency.find(params[:id])
  end

  def update
    @currency = Currency.find(params[:id])
    if @currency.update(currency_params)
      redirect_to admin_currencies_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
  def currency_params
    params.require(:currency).permit(:name, :label)
  end
end

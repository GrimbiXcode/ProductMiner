class Admin::CurrenciesController < AdminController
  def index
    allowed_sorts = %w[id name label]
    @sort = allowed_sorts.include?(params[:sort]) ? params[:sort] : 'id'
    @direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'

    scope = Currency.left_joins(:countries).distinct

    @currencies = scope.order("currencies.#{@sort} #{@direction}")

    @currencies = @currencies.page(params[:page]) if @currencies.respond_to?(:page)
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

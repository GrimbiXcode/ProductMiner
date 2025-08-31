class Admin::CountriesController < AdminController
  def index
    allowed_sorts = %w[id name currency]
    @sort = allowed_sorts.include?(params[:sort]) ? params[:sort] : 'id'
    @direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'

    scope = Country.left_joins(:currency)

    order_clause = if @sort == 'currency'
                     "currencies.name #{@direction}"
                   else
                     "countries.#{@sort} #{@direction}"
                   end

    @countries = scope.order(order_clause)
    @countries = @countries.page(params[:page]) if @countries.respond_to?(:page)
  end

  def show
    @country = Country.find(params[:id])
  end

  def new
    @country = Country.new
  end

  def create
    @country = Country.new(country_params)
    if @country.save
      redirect_to admin_countries_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @country = Country.find(params[:id])
  end

  def update
    @country = Country.find(params[:id])
    if @country.update(country_params)
      redirect_to admin_countries_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @country = Country.find(params[:id])
    @country.destroy
    redirect_to admin_countries_path
  end

  private
  def country_params
    params.require(:country).permit(:name, :currency_id)
  end
end

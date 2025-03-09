class Admin::CountriesController < AdminController
  def index
    @countries = Country.left_joins(:currency).all
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

  private
  def country_params
    params.require(:country).permit(:name, :currency_id)
  end
end

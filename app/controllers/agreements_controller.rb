class AgreementsController < ApplicationController
  def index
    @agreements = Agreement.all
  end

  def new
    @agreement = Agreement.new
  end

  def create
    @agreement = Agreement.new(agreement_params)

    puts "FILE: "
    file = @agreement.attachment

    if @agreement.save
      redirect_to '/agreements', notice: "The agreement #{@agreement.name} has been uploaded."
    else
      render 'new'
    end
  end

  def destroy
    @agreement = Agreement.find(params[:id])
    @agreement.destroy
    redirect_to '/agreements', notice: "The agreement #{@agreement.name} has been deleted"
  end

  private
    def agreement_params
      params.require(:agreement).permit(:name, :attachment)
    end
end

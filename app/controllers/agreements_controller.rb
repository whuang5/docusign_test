class AgreementsController < ApplicationController
  def index
    @agreements = Agreement.all
  end

  def new
    @agreement = Agreement.new
  end

  def create
    #make status pending
    params = agreement_params
    params[:status] = "pending"

    @agreement = Agreement.new(params)

    # puts "FILE: "
    # file = @agreement.attachment

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
      params.require(:agreement).permit(:name, :attachment, :emails, :status)
    end
end

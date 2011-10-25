class CirculationStatusesController < InheritedResources::Base
  respond_to :html, :json
  load_and_authorize_resource

  def update
    @circulation_status = CirculationStatus.find(params[:id])
    if params[:position]
      @circulation_status.insert_at(params[:position])
      redirect_to circulation_statuses_url
      return
    end
    update!
  end
end

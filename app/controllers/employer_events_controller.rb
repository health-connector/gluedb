class EmployerEventsController < ApplicationController
  load_and_authorize_resource

  def index
    @employer_events = EmployerEvents.sort(event_time: 1)
  end
end

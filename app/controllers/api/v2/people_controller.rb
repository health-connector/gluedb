class Api::V2::PeopleController < ApplicationController

  def index

    clean_hbx_member_id = Regexp.new(Regexp.escape(params[:hbx_id].to_s))

    # @people = Person.where('members.hbx_member_id' => clean_hbx_member_id)


    search = {'members.hbx_member_id' => clean_hbx_member_id}
    if(!params[:ids].nil? && !params[:ids].empty?)
      search['_id'] = {"$in" => params[:ids]}
    end

    @people = Person.where(search)

    page_number = params[:page]
    page_number ||= 1
    @people = @people.page(page_number).per(15)

    Caches::MongoidCache.with_cache_for(Carrier) do
      render "index"
    end
  end
  
  def get_person_by_ssn
    ssn = Regexp.new(Regexp.escape(params[:ssn].to_s))
    first_name = Regexp.new(Regexp.escape(params[:first_name].to_s))
    dob = Regexp.new(Regexp.escape(params[:date_of_birth].to_s))
    
    @people = Queries::ExistingPersonQuery.new(ssn, first_name, dob)
  end

  def show
    @person = Person.find(params[:id])
  end
end

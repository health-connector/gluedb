class Api::V2::ApplicationGroupsController < ApplicationController

  def index
    search = {}
    if(!params[:ids].nil? && !params[:ids].empty?)
      search['_id'] = {"$in" => params[:ids]}
    end

    @groups = Family.where(search)

    page_number = params[:page]
    page_number ||= 1
    @groups = @groups.page(page_number).per(30)
    peep_ids = @groups.inject([]) do |acc, ag|
      acc + ag.person_ids
    end
    peeps = Person.where("id" => {"$in" => peep_ids})
    lt_p = {}
    peeps.each do |per|
      lt_p[per.id] = per
      per.members.each do |m|
        Rails.cache.write("people/by_member_id/#{m.hbx_member_id}", per)
      end
    end
    Caches::CustomCache.with_custom_cache(Person, "ag_lookup", lt_p) do
      Caches::MongoidCache.with_cache_for(Carrier) do
        render 'index'
      end
    end
    Rails.cache.delete_matched("people/by_member_id")
  end

  def show
    Caches::MongoidCache.with_cache_for(Carrier) do
      @group = Family.find(params[:id])
      render 'show'
    end
  end
end

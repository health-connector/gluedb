class EditApplicationGroupForm  
  include ActiveModel::Conversion
  # include ActiveModel::Validations
  extend ActiveModel::Naming

  GroupMember = Struct.new(:remove_selected, :name, :person_id) do
    def initialize(h)
      super(*h.values_at(:remove_selected, :name, :person_id))
    end

    def persisted?
      false
    end
  end

  attr_accessor :people
  attr_accessor :application_group

  def initialize(params = {})
    @family = Family.find(params[:id])
      
    if (false)
      ppl_hash = params[:edit_application_form].fetch(:people_attributes) { {} }
      @people = ppl_hash.values.map { |person| GroupMember.new(person) }
    else
      @people = group_members
    end
  end

  def people_attributes=(pas)
  end

  def persisted?; false; end
  private

    def group_members
      @family.people.map do |person|
        GroupMember.new(remove_selected: false, name: person.name_full, person_id: person.id)
      end
    end
end

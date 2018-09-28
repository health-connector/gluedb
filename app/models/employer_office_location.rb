class EmployerOfficeLocation 
  include Mongoid::Document

  include MergingModel


  field :id, type: String
  field :name, type: String
  field :is_primary, type: Boolean 

  embeds_many :addresses, :inverse_of => :employer
  accepts_nested_attributes_for :addresses, reject_if: :all_blank, allow_destroy: true

  embeds_many :phones, :inverse_of => :employer
  accepts_nested_attributes_for :phones, reject_if: :all_blank, allow_destroy: true

  embedded_in :employer, :inverse_of => :employer_contacts 



end

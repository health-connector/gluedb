module RemoteResources
  class Person
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'person'
    namespace 'cv'

    element :name_first, String,  tag: "person_name/cv:person_given_name"

    element :name_last, String, tag: "person_name/cv:person_surname"

    element :name_full, String, tag: "person_name/cv:person_full_name"

    element :name_middle, String, tag: "person_name/cv:person_middle_name"

    element :name_pfx, String, tag: "person_name/cv:person_name_prefix_text"

    element :name_sfx, String, tag: "person_name/cv:person_name_suffix_text"
  end
end

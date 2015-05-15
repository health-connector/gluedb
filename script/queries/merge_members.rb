dups = {

}

dups.each do |k,v|
  auth = Person.find_for_member_id(k)
  nauth = Person.find_for_member_id(v)
  unless auth.members.count == 1 || nauth.members.count == 1
    puts [auth.members.inspect, nauth.members.inspect]
  else
    cloned = nauth.members.first.clone
    nauth.members.first.destroy
    auth.employer = nauth.employer
    nauth.employer = nil
    auth.members << cloned
    word = nauth.comments.build
    word.content = "This account no longer has any policies associated with it. All policies are now under ID #{k}."
    word.user = "joe.kramer@dc.gov"
    word.save!
    nauth.save!
    auth.save!
  end
end

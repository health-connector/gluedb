namespace :ct_demo do
  def build_admin_user(email, encrypted_pw)
    admin_user = User.new({
      email: email,
      role: "admin",
      approved: true
    })
    admin_user.save(validate: false)
    User.where({email: email}).update_all({"$set" => {encrypted_password: encrypted_pw}})
  end

  desc "Load Demo Users"
  task :load_users => :environment do
    build_admin_user("admin@dc.gov", "$2a$10$cg1txu.K24FFlg6fX0EJGuXffFS8BxD4pZDHo8EyfFHf/P9.qtysK")
    build_admin_user("saadi.mirza@dc.gov", "$2a$10$ukBUWityxeFrC44dMRBluevlYx6BTwIlwqsIyYqPSlBx.BTb0HBaK")
    build_admin_user("trey.evans@dc.gov", "$2a$10$hGCqQmTL3Nm0loIE62Xd0u/BJilfBppktnWAv5UdcNt5yRIHuMM0q")
    build_admin_user("sheheryar.tariq@dc.gov", "$2a$10$i.KTKf64K.ZIKv4wjFGZh.OYa1En0mw1XduNp7tBjDY1h7gpdU/Q2")
    build_admin_user("jason.sparks@dc.gov", "$2a$10$U7spXo4nUqEnyzNNG9nCV./FOTrdFe73Y/QTJBJBxW6lMFy55qwKi")
    build_admin_user("hannah.turner@dc.gov", "$2a$10$COumPZxJ4gPrRyQrOcARd.dcVxh0h1LcF5nbD3HRS4HlTyLuYR.NC")
    build_admin_user("alix.pereira@dc.gov", "$2a$10$7rjoye2ZL7Y5yJTFbJbbSOKNFAsd/.Jv78AVcaecP511SvyQHxOI.")
    build_admin_user("luis.vasquez3@dc.gov", "$2a$10$NdJvFDMAUCYb50ZV10ep2Ozs3/tqmxP985AqYK5X/82rnI9q6aMY2")
    build_admin_user("kenneth.taylor-sutton@dc.gov", "$2a$10$hXRtJgByev2ayn6iUGCzjuD2LyNofsHV2dGx6c0ua86xTLl1WoWrq")
    build_admin_user("jennifer.beeson@dc.gov", "$2a$10$ajMOuwVI5.WAPbtuV.mGHu6xkGXLrao/mZANuu2e36lEmX6K0ZxQW")
  end
end
